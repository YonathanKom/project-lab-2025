from typing import Dict, Any
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api import deps
from app.models.user import User
from app.schemas.data_import import (
    DataImportResponse,
    DataImportStatus,
    ManualImportRequest,
)
from app.services.data_import_service import DataImportService

router = APIRouter()


@router.post("/trigger", response_model=DataImportResponse)
async def trigger_manual_import(
    import_request: ManualImportRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Manually trigger data import for specified chains"""

    data_import_service = DataImportService()

    if import_request.chain_names:
        # Import specific chains
        results = {
            "started_at": None,
            "chains_processed": 0,
            "total_items_found": 0,
            "total_stores_found": 0,
            "errors": [],
        }

        for chain_name in import_request.chain_names:
            if chain_name not in data_import_service.chain_configs:
                results["errors"].append(f"Unknown chain: {chain_name}")
                continue

            try:
                config = data_import_service.chain_configs[chain_name]
                chain_result = await data_import_service._import_chain_data(
                    chain_name, config
                )

                if not results["started_at"]:
                    results["started_at"] = chain_result.get("started_at")

                results["chains_processed"] += 1
                results["total_items_found"] += chain_result.get("items_processed", 0)
                results["total_stores_found"] += chain_result.get("stores_processed", 0)

                if "error" in chain_result:
                    results["errors"].append(f"{chain_name}: {chain_result['error']}")

            except Exception as e:
                results["errors"].append(f"Failed to import {chain_name}: {str(e)}")

        return DataImportResponse(**results)
    else:
        # Import all chains
        results = await data_import_service.import_all_chains()
        return DataImportResponse(**results)


@router.get("/status", response_model=DataImportStatus)
async def get_import_status(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Get current data import status"""

    data_import_service = DataImportService()
    status = await data_import_service.get_import_status()

    return DataImportStatus(**status)


@router.get("/chains", response_model=Dict[str, Any])
async def get_available_chains(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Get list of available chains for import"""

    data_import_service = DataImportService()

    return {
        "available_chains": list(data_import_service.chain_configs.keys()),
        "chain_details": {
            name: {
                "username": config["username"],
                "file_pattern": config.get("file_pattern", "Unknown"),
            }
            for name, config in data_import_service.chain_configs.items()
        },
    }


@router.post("/test-connection")
async def test_government_connection(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Test connection to government data source"""

    data_import_service = DataImportService()

    # Test connection with first available chain
    if not data_import_service.chain_configs:
        return {"status": "error", "message": "No chains configured"}

    chain_name = list(data_import_service.chain_configs.keys())[0]
    config = data_import_service.chain_configs[chain_name]

    try:
        # Test login only (don't download files)
        session = data_import_service._login_to_website(
            config["username"], config["password"]
        )

        if session:
            return {
                "status": "success",
                "message": f"Successfully connected to government site with {chain_name} credentials",
                "chain_tested": chain_name,
            }
        else:
            return {
                "status": "error",
                "message": f"Failed to authenticate with government site using {chain_name} credentials",
                "chain_tested": chain_name,
            }

    except Exception as e:
        return {
            "status": "error",
            "message": f"Connection test failed: {str(e)}",
            "chain_tested": chain_name,
        }


@router.post("/stores/trigger", response_model=DataImportResponse)
async def trigger_store_directory_import(
    import_request: ManualImportRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Manually trigger store directory import for specified chains"""

    data_import_service = DataImportService()

    if import_request.chain_names:
        # Import specific chains
        results = {
            "started_at": None,
            "chains_processed": 0,
            "total_items_found": 0,
            "total_stores_found": 0,
            "stores_geocoded": 0,
            "geocoding_failures": 0,
            "errors": [],
        }

        for chain_name in import_request.chain_names:
            if chain_name not in data_import_service.chain_configs:
                results["errors"].append(f"Unknown chain: {chain_name}")
                continue

            try:
                config = data_import_service.chain_configs[chain_name]
                chain_result = (
                    await data_import_service._import_store_directory_chain_data(
                        chain_name, config
                    )
                )

                if not results["started_at"]:
                    results["started_at"] = chain_result.get("started_at")

                results["chains_processed"] += 1
                results["total_stores_found"] += chain_result.get("stores_processed", 0)
                results["stores_geocoded"] += chain_result.get("stores_geocoded", 0)
                results["geocoding_failures"] += chain_result.get(
                    "geocoding_failures", 0
                )

                if "error" in chain_result:
                    results["errors"].append(f"{chain_name}: {chain_result['error']}")

            except Exception as e:
                results["errors"].append(f"Failed to import {chain_name}: {str(e)}")

        return DataImportResponse(**results)
    else:
        # Import all chains
        results = await data_import_service.import_all_store_directories()
        return DataImportResponse(**results)
