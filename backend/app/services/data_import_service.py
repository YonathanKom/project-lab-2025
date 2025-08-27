import asyncio
import gzip
from io import BytesIO
from typing import Dict, List, Optional
from datetime import datetime, UTC
import sys
import json
import logging
import requests
from bs4 import BeautifulSoup
from app.services.price_service import PriceService
from app.core.database import SessionLocal
import xml.etree.ElementTree as ET
import os
import googlemaps
from typing import Tuple

logger = logging.getLogger(__name__)


class StoreLocationFinder:
    def __init__(self, api_key: str):
        """Initialize the store finder with Google Maps API key."""
        self.gmaps = googlemaps.Client(key=api_key)

    def find_store_location(
        self, store_name: str
    ) -> Tuple[Optional[float], Optional[float], Optional[str]]:
        """Find the latitude and longitude of a store using Google Places API."""
        # Build search queries with different specificity levels

        try:
            # Search for places
            places_result = self.gmaps.places(query=store_name, language="he")
            print(places_result)

            if places_result["results"]:
                # Get the first (most relevant) result
                place = places_result["results"][0]

                location = place["geometry"]["location"]
                lat = location["lat"]
                lng = location["lng"]
                address = place["formatted_address"]

                return lat, lng, address

        except Exception:
            return None, None, None


class DataImportService:
    """Service for importing price data from government sources"""

    def __init__(self):
        self.login_url = "https://url.publishedprices.co.il/login"
        self.login_post_url = "https://url.publishedprices.co.il/login/user"
        self.redirect_url = "https://url.publishedprices.co.il/file"
        # Initialize geocoder if API key is available
        self.geocoder = None
        api_key = os.getenv("GOOGLE_MAPS_API_KEY")
        if api_key:
            self.geocoder = StoreLocationFinder(api_key)

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
            "started_at": datetime.now(UTC).isoformat(),
            "chains_processed": 0,
            "total_items_found": 0,
            "total_stores_found": 0,
            "stores_geocoded": 0,
            "geocoding_failures": 0,
            "errors": [],
        }

        for chain_name, config in self.chain_configs.items():
            try:
                chain_result = await self._import_chain_data(chain_name, config)

                results["total_items_found"] += chain_result.get("items_processed", 0)
                results["total_stores_found"] += chain_result.get("stores_processed", 0)
                results["stores_geocoded"] += chain_result.get("stores_geocoded", 0)
                results["geocoding_failures"] += chain_result.get(
                    "geocoding_failures", 0
                )

            except Exception as e:
                error_msg = f"Failed to import {chain_name}: {str(e)}"
                results["errors"].append(error_msg)

        results["completed_at"] = datetime.now(UTC).isoformat()

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
            "started_at": datetime.now(UTC).isoformat(),
            "items_processed": 0,
            "stores_processed": 0,
            "stores_geocoded": 0,
            "geocoding_failures": 0,
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
                        xml_str = xml_content.decode("utf-8")

                        # Detect file type based on XML structure
                        if self._is_store_directory_file(xml_str):
                            # Process store directory
                            store_result = self._process_store_directory(
                                xml_str, price_service
                            )
                            result["stores_processed"] += store_result.get(
                                "stores_processed", 0
                            )
                            result["stores_geocoded"] += store_result.get(
                                "stores_geocoded", 0
                            )
                            result["geocoding_failures"] += store_result.get(
                                "geocoding_failures", 0
                            )
                            logger.info(
                                f"Processed store directory {file_url}: {store_result.get('stores_processed', 0)} stores"
                            )
                        else:
                            # Process price data
                            parsed_data = price_service.parse_xml_data(xml_str)
                            result["items_processed"] += len(
                                parsed_data.get("items", [])
                            )
                            result["stores_processed"] += 1
                            logger.info(
                                f"Parsed price file {file_url}: {len(parsed_data.get('items', []))} items"
                            )

                        result["files_processed"] += 1

                except Exception as e:
                    logger.error(f"Failed to process file {file_url}: {str(e)}")

            result["completed_at"] = datetime.now(UTC).isoformat()

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
        """Download XML file (gzipped or plain)"""
        try:
            response = session.get(file_url, stream=True, timeout=60)
            response.raise_for_status()

            # Check if file is gzipped based on URL or content
            if file_url.endswith(".gz"):
                # Extract gzipped content
                gzipped_content = BytesIO(response.content)
                with gzip.open(gzipped_content, "rb") as gz_file:
                    xml_content = gz_file.read()
            else:
                # Plain XML file
                xml_content = response.content

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

    def _is_store_directory_file(self, xml_content: str) -> bool:
        """Detect if XML file is a store directory based on structure"""
        try:
            root = ET.fromstring(xml_content)
            # Store directory files have SubChains and Stores elements
            return (
                root.find("ChainName") is not None
                and root.find("SubChains") is not None
            )
        except ET.ParseError:
            return False

    def _parse_store_directory_xml(self, xml_content: str) -> Dict[str, any]:
        """Parse store directory XML and extract store information"""
        try:
            root = ET.fromstring(xml_content)

            chain_id = (
                root.find("ChainID").text if root.find("ChainID") is not None else None
            )
            chain_name = (
                root.find("ChainName").text
                if root.find("ChainName") is not None
                else None
            )

            stores = []
            subchains_element = root.find("SubChains")

            if subchains_element is not None:
                for subchain in subchains_element.findall("SubChain"):
                    subchain_id = (
                        subchain.find("SubChainID").text
                        if subchain.find("SubChainID") is not None
                        else None
                    )
                    subchain_name = (
                        subchain.find("SubChainName").text
                        if subchain.find("SubChainName") is not None
                        else None
                    )

                    stores_element = subchain.find("Stores")
                    if stores_element is not None:
                        for store in stores_element.findall("Store"):
                            store_data = {
                                "chain_id": chain_id,
                                "chain_name": chain_name,
                                "subchain_id": subchain_id,
                                "subchain_name": subchain_name,
                                "store_id": store.find("StoreID").text
                                if store.find("StoreID") is not None
                                else None,
                                "store_name": store.find("StoreName").text
                                if store.find("StoreName") is not None
                                else None,
                                "address": store.find("Address").text
                                if store.find("Address") is not None
                                else None,
                                "city": store.find("City").text
                                if store.find("City") is not None
                                else None,
                                "bikoret_no": store.find("BikoretNo").text
                                if store.find("BikoretNo") is not None
                                else None,
                            }
                            stores.append(store_data)

            return {"chain_id": chain_id, "chain_name": chain_name, "stores": stores}

        except ET.ParseError as e:
            raise ValueError(f"Invalid store directory XML format: {str(e)}")

    def _process_store_directory(
        self, xml_content: str, price_service: PriceService
    ) -> Dict[str, int]:
        """Process store directory data and update database with geocoded locations"""
        try:
            parsed_data = self._parse_store_directory_xml(xml_content)

            result = {
                "stores_processed": 0,
                "stores_geocoded": 0,
                "geocoding_failures": 0,
            }

            # Create or update chain
            price_service._create_or_update_chain(
                parsed_data["chain_id"], parsed_data["chain_name"]
            )

            # Process each store
            for store_data in parsed_data["stores"]:
                try:
                    # Geocode store location using ChainName + StoreName
                    lat, lng, formatted_address = None, None, None

                    if (
                        self.geocoder
                        and store_data["store_name"]
                        and parsed_data["chain_name"]
                    ):
                        # Construct search query: ChainName + StoreName
                        search_query = (
                            f"{parsed_data['chain_name']} {store_data['store_name']}"
                        )

                        lat, lng, formatted_address = self.geocoder.find_store_location(
                            search_query
                        )

                        if lat and lng:
                            result["stores_geocoded"] += 1
                            logger.info(f"Geocoded {search_query}: {lat}, {lng}")
                        else:
                            result["geocoding_failures"] += 1
                            logger.warning(f"Failed to geocode {search_query}")

                    # Update store in database
                    price_service._create_or_update_store_with_location(
                        store_id=store_data["store_id"],
                        chain_id=parsed_data["chain_id"],
                        bikoret_no=store_data["bikoret_no"],
                        name=store_data["store_name"],
                        address=store_data["address"]
                        if store_data["address"] != "unknown"
                        else None,
                        city=store_data["city"],
                        latitude=lat,
                        longitude=lng,
                    )

                    result["stores_processed"] += 1

                except Exception as e:
                    logger.error(
                        f"Failed to process store {store_data.get('store_name', 'unknown')}: {str(e)}"
                    )
                    continue

            return result

        except Exception as e:
            logger.error(f"Failed to process store directory: {str(e)}")
            return {
                "stores_processed": 0,
                "stores_geocoded": 0,
                "geocoding_failures": 0,
            }

    async def import_all_store_directories(self) -> Dict[str, any]:
        """Import store directories for all configured chains"""
        results = {
            "started_at": datetime.now(UTC).isoformat(),
            "chains_processed": 0,
            "total_items_found": 0,
            "total_stores_found": 0,
            "stores_geocoded": 0,
            "geocoding_failures": 0,
            "errors": [],
        }

        for chain_name, config in self.chain_configs.items():
            try:
                chain_result = await self._import_store_directory_chain_data(
                    chain_name, config
                )

                results["chains_processed"] += 1
                results["total_stores_found"] += chain_result.get("stores_processed", 0)
                results["stores_geocoded"] += chain_result.get("stores_geocoded", 0)
                results["geocoding_failures"] += chain_result.get(
                    "geocoding_failures", 0
                )

            except Exception as e:
                error_msg = f"Failed to import {chain_name}: {str(e)}"
                results["errors"].append(error_msg)

        results["completed_at"] = datetime.now(UTC).isoformat()
        return results

    async def _import_store_directory_chain_data(
        self, chain_name: str, config: Dict
    ) -> Dict[str, any]:
        """Import store directory data for a specific chain"""
        username = config["username"]
        password = config["password"]

        # Run the blocking operations in a thread pool
        loop = asyncio.get_event_loop()

        def blocking_import():
            return self._perform_store_directory_import(chain_name, username, password)

        return await loop.run_in_executor(None, blocking_import)

    def _perform_store_directory_import(
        self, chain_name: str, username: str, password: str
    ) -> Dict[str, any]:
        """Perform the actual store directory import for a chain (blocking operation)"""
        result = {
            "chain_name": chain_name,
            "started_at": datetime.now(UTC).isoformat(),
            "stores_processed": 0,
            "stores_geocoded": 0,
            "geocoding_failures": 0,
            "files_processed": 0,
        }

        db = SessionLocal()

        try:
            price_service = PriceService(db)

            # Step 1: Login to the website
            session = self._login_to_website(username, password)
            if not session:
                raise Exception("Failed to authenticate with government website")

            # Step 2: Get available store directory files
            file_urls = self._get_store_directory_files(session, chain_name)

            # Step 3: Process each file
            for file_url in file_urls:
                try:
                    xml_content = self._download_and_extract_file(session, file_url)

                    if xml_content:
                        xml_str = xml_content.decode("utf-16le")

                        # Process store directory
                        store_result = self._process_store_directory(
                            xml_str, price_service
                        )
                        result["stores_processed"] += store_result.get(
                            "stores_processed", 0
                        )
                        result["stores_geocoded"] += store_result.get(
                            "stores_geocoded", 0
                        )
                        result["geocoding_failures"] += store_result.get(
                            "geocoding_failures", 0
                        )

                        result["files_processed"] += 1

                        logger.info(
                            f"Processed store directory {file_url}: {store_result.get('stores_processed', 0)} stores"
                        )

                except Exception as e:
                    logger.error(f"Failed to process file {file_url}: {str(e)}")

            result["completed_at"] = datetime.now(UTC).isoformat()

        except Exception as e:
            result["error"] = str(e)
        finally:
            db.close()

        return result

    def _get_store_directory_files(
        self, session: requests.Session, chain_name: str
    ) -> List[str]:
        """Get list of available store directory files for the chain using government API"""
        try:
            # The API endpoint to get the list of files in JSON format
            file_list_api = "https://url.publishedprices.co.il/file/json/dir"

            # First, fetch the CSRF token from the file list page
            response = session.get(self.redirect_url)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, "html.parser")
            csrftoken_tag = soup.find("meta", attrs={"name": "csrftoken"})
            csrftoken = csrftoken_tag.get("content") if csrftoken_tag else ""

            # Search for store directory files
            search_pattern = "Stores"

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

            # Build full URLs for files that match store directory pattern
            for file_info in files:
                file_name = file_info.get("fname", "")
                if file_name and file_name.startswith("Stores"):
                    file_url = f"https://url.publishedprices.co.il/file/d/{file_name}"
                    file_urls.append(file_url)

            logger.info(
                f"Found {len(file_urls)} store directory files for {chain_name}"
            )
            return file_urls

        except requests.exceptions.RequestException as e:
            logger.error(
                f"Network error while fetching store directory list for {chain_name}: {e}"
            )
            return []
        except json.JSONDecodeError as e:
            logger.error(f"Error decoding JSON response for {chain_name}: {e}")
            return []
        except Exception as e:
            logger.error(
                f"Unexpected error while fetching store directory list for {chain_name}: {e}"
            )
            return []
