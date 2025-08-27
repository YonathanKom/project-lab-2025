from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    Text,
    Boolean,
    ForeignKey,
    func,
)
from sqlalchemy.orm import relationship

from app.db.base_class import Base


class DataImportJob(Base):
    """Placeholder model for data import jobs"""

    __tablename__ = "data_import_jobs"

    id = Column(Integer, primary_key=True, index=True)
    chain_name = Column(String, nullable=False, index=True)
    status = Column(
        String, nullable=False, default="pending"
    )  # pending, running, completed, failed
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    files_processed = Column(Integer, default=0)
    items_processed = Column(Integer, default=0)
    stores_processed = Column(Integer, default=0)
    error_message = Column(Text, nullable=True)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    created_by = relationship("User", back_populates="data_import_jobs")


class DataImportHistory(Base):
    """Placeholder model for tracking import history"""

    __tablename__ = "data_import_history"

    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer, ForeignKey("data_import_jobs.id"), nullable=False)
    chain_name = Column(String, nullable=False, index=True)
    file_url = Column(String, nullable=False)
    file_size_bytes = Column(Integer, nullable=True)
    processing_time_seconds = Column(Integer, nullable=True)
    items_found = Column(Integer, default=0)
    stores_found = Column(Integer, default=0)
    success = Column(Boolean, default=False)
    error_details = Column(Text, nullable=True)
    processed_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    job = relationship("DataImportJob", backref="import_files")


class DataSourceConfig(Base):
    """Placeholder model for data source configurations"""

    __tablename__ = "data_source_configs"

    id = Column(Integer, primary_key=True, index=True)
    chain_name = Column(String, unique=True, nullable=False, index=True)
    username = Column(String, nullable=False)
    password = Column(String, nullable=False)  # Should be encrypted in production
    file_pattern = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    last_import_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    # Relationships
    created_by = relationship("User", back_populates="data_source_configs")
