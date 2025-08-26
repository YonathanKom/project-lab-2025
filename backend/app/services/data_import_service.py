import asyncio
import gzip
from io import BytesIO
from typing import Dict, List, Optional
from datetime import datetime
import sys
import json
import logging
import requests
from bs4 import BeautifulSoup
from app.services.price_service import PriceService
from app.core.database import SessionLocal

logger = logging.getLogger(__name__)


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

        db = SessionLocal()

        try:
            price_service = PriceService(db)

            # Step 1: Login to the website
            session = self._login_to_website(username, password)
            if not session:
                raise Exception("Failed to authenticate with government website")

            # Step 2: Get available files list (placeholder - would need to scrape file list)
            file_urls = self._get_available_files(session, chain_name)

            # Step 3: Process each file
            for file_url in file_urls:
                try:
                    xml_content = self._download_and_extract_file(session, file_url)

                    if xml_content:
                        parsed_data = price_service.parse_xml_data(
                            xml_content.decode("utf-8")
                        )

                        result["items_processed"] += len(parsed_data.get("items", []))
                        result["files_processed"] += 1

                        logger.info(
                            f"Parsed file {file_url}: {len(parsed_data.get('items', []))} items"
                        )

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
        """Get list of available files for the chain using government API"""
        try:
            # The API endpoint to get the list of files in JSON format
            file_list_api = "https://url.publishedprices.co.il/file/json/dir"

            # First, fetch the CSRF token from the file list page
            response = session.get(self.redirect_url)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, "html.parser")
            csrftoken_tag = soup.find("meta", attrs={"name": "csrftoken"})
            csrftoken = csrftoken_tag.get("content") if csrftoken_tag else ""

            # All chains use files starting with 'PriceFull'
            search_pattern = "PriceFull"

            # Payload based on the government API requirements
            payload = {
                "sEcho": "1",
                "iColumns": "5",
                "sColumns": ",,,,",
                "iDisplayStart": "0",
                "iDisplayLength": "1000",
                "mDataProp_0": "fname",
                "sSearch_0": "",
                "bRegex_0": "false",
                "bSearchable_0": "true",
                "bSortable_0": "true",
                "mDataProp_1": "typeLabel",
                "sSearch_1": "",
                "bRegex_1": "false",
                "bSearchable_1": "true",
                "bSortable_1": "false",
                "mDataProp_2": "size",
                "sSearch_2": "",
                "bRegex_2": "false",
                "bSearchable_2": "true",
                "bSortable_2": "true",
                "mDataProp_3": "ftime",
                "sSearch_3": "",
                "bRegex_3": "false",
                "bSearchable_3": "true",
                "bSortable_3": "true",
                "mDataProp_4": "",
                "sSearch_4": "",
                "bRegex_4": "false",
                "bSearchable_4": "true",
                "bSortable_4": "false",
                "sSearch": search_pattern,
                "bRegex": "false",
                "iSortingCols": "1",
                "iSortCol_0": "3",
                "sSortDir_0": "desc",
                "cd": "/",
                "csrftoken": csrftoken,
            }

            # Perform the POST request to get the file list JSON
            response = session.post(file_list_api, data=payload)
            response.raise_for_status()

            file_list_json = response.json()

            if "aaData" not in file_list_json:
                logger.warning(
                    f"API response format unexpected for {chain_name}, no 'aaData' key found"
                )
                return []

            files = file_list_json["aaData"]
            file_urls = []

            file_pattern = ""

            # Build full URLs for files that match the chain's specific pattern
            for file_info in files:
                file_name = file_info.get("fname", "")
                if file_name and file_name.startswith("PriceFull"):
                    # If chain has specific pattern, use it for additional filtering
                    if not file_pattern or self._matches_pattern(
                        file_name, file_pattern
                    ):
                        file_url = (
                            f"https://url.publishedprices.co.il/file/d/{file_name}"
                        )
                        file_urls.append(file_url)

            logger.info(f"Found {len(file_urls)} matching files for {chain_name}")
            return file_urls

        except requests.exceptions.RequestException as e:
            logger.error(
                f"Network error while fetching file list for {chain_name}: {e}"
            )
            return []
        except json.JSONDecodeError as e:
            logger.error(f"Error decoding JSON response for {chain_name}: {e}")
            return []
        except Exception as e:
            logger.error(
                f"Unexpected error while fetching file list for {chain_name}: {e}"
            )
            return []

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

    async def get_import_status(self) -> Dict[str, any]:
        """Get current import status (placeholder)"""
        return {
            "is_running": False,
            "last_run": None,
            "next_scheduled": None,
            "configured_chains": list(self.chain_configs.keys()),
            "total_imports_today": 0,
        }
