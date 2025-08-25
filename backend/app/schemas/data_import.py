from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class ManualImportRequest(BaseModel):
    """Schema for manual import trigger request"""

    chain_names: Optional[List[str]] = Field(
        None, description="Specific chains to import. If None, imports all chains"
    )


class DataImportResponse(BaseModel):
    """Schema for data import operation response"""

    started_at: Optional[str] = Field(
        None, description="ISO timestamp when import started"
    )
    completed_at: Optional[str] = Field(
        None, description="ISO timestamp when import completed"
    )
    chains_processed: int = Field(0, description="Number of chains processed")
    total_items_found: int = Field(0, description="Total items found across all chains")
    total_stores_found: int = Field(
        0, description="Total stores found across all chains"
    )
    errors: List[str] = Field(
        default_factory=list, description="List of error messages"
    )


class DataImportStatus(BaseModel):
    """Schema for import status response"""

    is_running: bool = Field(
        False, description="Whether an import is currently running"
    )
    last_run: Optional[str] = Field(None, description="ISO timestamp of last import")
    next_scheduled: Optional[str] = Field(
        None, description="ISO timestamp of next scheduled import"
    )
    configured_chains: List[str] = Field(
        default_factory=list, description="List of configured chain names"
    )
    total_imports_today: int = Field(0, description="Number of imports completed today")


class DataImportJobBase(BaseModel):
    """Base schema for data import jobs"""

    chain_name: str
    status: str = "pending"
    files_processed: int = 0
    items_processed: int = 0
    stores_processed: int = 0
    error_message: Optional[str] = None


class DataImportJobCreate(DataImportJobBase):
    """Schema for creating data import jobs"""

    pass


class DataImportJobUpdate(BaseModel):
    """Schema for updating data import jobs"""

    status: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    files_processed: Optional[int] = None
    items_processed: Optional[int] = None
    stores_processed: Optional[int] = None
    error_message: Optional[str] = None


class DataImportJobInDBBase(DataImportJobBase):
    """Base schema for data import jobs in database"""

    model_config = ConfigDict(from_attributes=True)

    id: int
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_by_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime


class DataImportJob(DataImportJobInDBBase):
    """Schema for data import job with relationships"""

    pass


class DataImportJobInDB(DataImportJobInDBBase):
    """Schema for data import job as stored in database"""

    pass


class DataImportHistoryBase(BaseModel):
    """Base schema for data import history"""

    chain_name: str
    file_url: str
    file_size_bytes: Optional[int] = None
    processing_time_seconds: Optional[int] = None
    items_found: int = 0
    stores_found: int = 0
    success: bool = False
    error_details: Optional[str] = None


class DataImportHistoryCreate(DataImportHistoryBase):
    """Schema for creating data import history records"""

    job_id: int


class DataImportHistoryInDBBase(DataImportHistoryBase):
    """Base schema for data import history in database"""

    model_config = ConfigDict(from_attributes=True)

    id: int
    job_id: int
    processed_at: datetime


class DataImportHistory(DataImportHistoryInDBBase):
    """Schema for data import history with relationships"""

    pass


class DataImportHistoryInDB(DataImportHistoryInDBBase):
    """Schema for data import history as stored in database"""

    pass


class DataSourceConfigBase(BaseModel):
    """Base schema for data source configurations"""

    chain_name: str
    username: str
    password: str
    file_pattern: Optional[str] = None
    is_active: bool = True


class DataSourceConfigCreate(DataSourceConfigBase):
    """Schema for creating data source configurations"""

    pass


class DataSourceConfigUpdate(BaseModel):
    """Schema for updating data source configurations"""

    username: Optional[str] = None
    password: Optional[str] = None
    file_pattern: Optional[str] = None
    is_active: Optional[bool] = None


class DataSourceConfigInDBBase(DataSourceConfigBase):
    """Base schema for data source configurations in database"""

    model_config = ConfigDict(from_attributes=True)

    id: int
    last_import_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    created_by_id: Optional[int] = None


class DataSourceConfig(DataSourceConfigInDBBase):
    """Schema for data source configuration with relationships"""

    pass


class DataSourceConfigInDB(DataSourceConfigInDBBase):
    """Schema for data source configuration as stored in database"""

    pass
