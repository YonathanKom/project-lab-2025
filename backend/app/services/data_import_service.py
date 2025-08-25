import asyncio
import gzip
from io import BytesIO
from typing import Dict, List, Optional
import xml.etree.ElementTree as ET
from datetime import datetime
import sys

import requests
from bs4 import BeautifulSoup


class DataImportService:
    """Service for importing price data from government sources"""

    def __init__(self):
        self.login_url = "https://url.publishedprices.co.il/login"
        self.login_post_url = "https://url.publishedprices.co.il/login/user"
        self.redirect_url = "https://url.publishedprices.co.il/file"

        # Configuration for different chains
        self.chain_configs = {
            "TivTaam": {
                "username": "TivTaam",
                "password": "",
                "file_pattern": "PriceFull7290873255550-523-*.gz",
            }
            # Add more chains here as needed
        }

    async def import_all_chains(self) -> Dict[str, any]:
        """Import data for all configured chains"""
        results = {
            "started_at": datetime.utcnow().isoformat(),
            "chains_processed": 0,
            "total_items_found": 0,
            "total_stores_found": 0,
            "errors": [],
        }

        for chain_name, config in self.chain_configs.items():
            try:
                chain_result = await self._import_chain_data(chain_name, config)

                results["chains_processed"] += 1
                results["total_items_found"] += chain_result.get("items_processed", 0)
                results["total_stores_found"] += chain_result.get("stores_processed", 0)

            except Exception as e:
                error_msg = f"Failed to import {chain_name}: {str(e)}"
                results["errors"].append(error_msg)

        results["completed_at"] = datetime.utcnow().isoformat()

        return results

    async def _import_chain_data(self, chain_name: str, config: Dict) -> Dict[str, any]:
        """Import data for a specific chain"""
        username = config["username"]
        password = config["password"]

        # Run the blocking operations in a thread pool
        loop = asyncio.get_event_loop()

        def blocking_import():
            return self._perform_chain_import(chain_name, username, password)

        return await loop.run_in_executor(None, blocking_import)

    def _perform_chain_import(
        self, chain_name: str, username: str, password: str
    ) -> Dict[str, any]:
        """Perform the actual import for a chain (blocking operation)"""
        result = {
            "chain_name": chain_name,
            "started_at": datetime.utcnow().isoformat(),
            "items_processed": 0,
            "stores_processed": 0,
            "files_processed": 0,
        }

        try:
            # Step 1: Login to the website
            session = self._login_to_website(username, password)
            if not session:
                raise Exception("Failed to authenticate with government website")

            # Step 2: Get available files list (placeholder - would need to scrape file list)
            file_urls = self._get_available_files(session, chain_name)

            # Step 3: Process each file
            for file_url in file_urls[:1]:  # Limit to 1 file for now
                try:
                    xml_content = self._download_and_extract_file(session, file_url)
                    if xml_content:
                        file_result = self._process_xml_content(xml_content, chain_name)
                        result["items_processed"] += file_result.get("items_found", 0)
                        result["stores_processed"] += file_result.get("stores_found", 0)
                        result["files_processed"] += 1

                except Exception:
                    pass  # Skip failed files

            result["completed_at"] = datetime.utcnow().isoformat()

        except Exception as e:
            result["error"] = str(e)

        return result

    def _login_to_website(
        self, username: str, password: str
    ) -> Optional[requests.Session]:
        """Login to the government website"""
        session = requests.Session()

        try:
            response = session.get(self.login_url, timeout=30)
            response.raise_for_status()

            # Parse CSRF token
            soup = BeautifulSoup(response.content, "html.parser")
            csrftoken_tag = soup.find("meta", attrs={"name": "csrftoken"})

            if not csrftoken_tag:
                return None

            csrftoken = csrftoken_tag.get("content")

            # Prepare login data
            payload = {
                "username": username,
                "password": password,
                "csrftoken": csrftoken,
            }

            headers = {"Referer": self.login_url, "X-CSRF-Token": csrftoken}

            # Perform login
            login_response = session.post(
                self.login_post_url,
                data=payload,
                headers=headers,
                timeout=30,
                allow_redirects=False,
            )

            if login_response.status_code == 302:
                return session
            else:
                return None

        except requests.exceptions.Timeout:
            print(
                "Request timed out after 30 seconds. This might be a slow connection or a firewall issue.",
                file=sys.stderr,
            )
            return None
        except requests.exceptions.SSLError:
            print(
                "SSL/TLS Error: Cannot establish a secure connection. This may be an issue with the server's certificate or your system's trust store.",
                file=sys.stderr,
            )
            return None
        except requests.exceptions.RequestException as e:
            print(
                f"A general request error occurred: {e}. Check your network connection or try again later.",
                file=sys.stderr,
            )
            return None

    def _get_available_files(
        self, session: requests.Session, chain_name: str
    ) -> List[str]:
        """Get list of available files for the chain (placeholder implementation)"""
        # This is a placeholder - in reality you'd need to scrape the file listing page
        # For now, return a sample file URL based on the pattern from your script
        sample_file = "https://url.publishedprices.co.il/file/d/PriceFull7290873255550-523-202508240502.gz"

        return [sample_file]

    def _download_and_extract_file(
        self, session: requests.Session, file_url: str
    ) -> Optional[bytes]:
        """Download and extract gzipped XML file"""
        try:
            response = session.get(file_url, stream=True, timeout=60)
            response.raise_for_status()

            # Extract gzipped content
            gzipped_content = BytesIO(response.content)

            with gzip.open(gzipped_content, "rb") as gz_file:
                xml_content = gz_file.read()

            return xml_content

        except Exception:
            return None

    def _process_xml_content(
        self, xml_content: bytes, chain_name: str
    ) -> Dict[str, any]:
        """Process the XML content and extract items/stores (placeholder)"""
        result = {
            "chain_name": chain_name,
            "file_size_bytes": len(xml_content),
            "items_found": 0,
            "stores_found": 0,
            "processing_time_seconds": 0,
        }

        start_time = datetime.utcnow()

        try:
            # Parse XML
            root = ET.fromstring(xml_content.decode("utf-8"))

            # Count items and stores (placeholder parsing)
            items = root.findall(".//Item") if root.findall(".//Item") else []
            stores = root.findall(".//Store") if root.findall(".//Store") else []

            result["items_found"] = len(items)
            result["stores_found"] = len(stores)

            # Simulate database operations with detailed logging
            self._simulate_database_operations(items, stores, chain_name)

        except ET.ParseError as e:
            result["error"] = f"XML parsing error: {e}"
        except Exception as e:
            result["error"] = str(e)

        end_time = datetime.utcnow()
        result["processing_time_seconds"] = (end_time - start_time).total_seconds()

        return result

    def _simulate_database_operations(self, items: List, stores: List, chain_name: str):
        """Simulate what database operations would be performed"""
        # Placeholder for database operations
        # In reality, this would:
        # - Upsert chain record
        # - Upsert store records
        # - Upsert item records
        # - Update price records
        pass

    async def get_import_status(self) -> Dict[str, any]:
        """Get current import status (placeholder)"""
        return {
            "is_running": False,  # Would track actual running status
            "last_run": None,  # Would track from database/cache
            "next_scheduled": None,  # Would calculate from schedule
            "configured_chains": list(self.chain_configs.keys()),
            "total_imports_today": 0,  # Would query from database
        }
