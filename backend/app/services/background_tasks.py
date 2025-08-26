import asyncio
import logging
from typing import Optional

from app.core.database import SessionLocal
from app.services.prediction_service import PredictionService
from app.services.data_import_service import DataImportService
from app.core.config import settings

logger = logging.getLogger(__name__)


class BackgroundTaskService:
    def __init__(self):
        self.apriori_task: Optional[asyncio.Task] = None
        self.data_import_task: Optional[asyncio.Task] = None
        self.is_running = False

    async def start_periodic_tasks(self):
        """Start all background tasks"""
        logger.info("Starting background tasks...")
        logger.info(
            f"Apriori generation configured: every {settings.APRIORI_GENERATION_INTERVAL_HOURS}h, "
            f"startup delay {settings.APRIORI_STARTUP_DELAY_MINUTES}m, "
            f"error retry {settings.APRIORI_ERROR_RETRY_MINUTES}m"
        )
        self.is_running = True

        # Start Apriori rule generation task
        # self.apriori_task = asyncio.create_task(self._periodic_apriori_generation())

        # Start data import task
        # self.data_import_task = asyncio.create_task(self._periodic_data_import())

        logger.info("Background tasks started successfully")

    async def stop_periodic_tasks(self):
        """Stop all background tasks"""
        logger.info("Stopping background tasks...")
        self.is_running = False

        # if self.apriori_task:
        #     self.apriori_task.cancel()
        #     try:
        #         await self.apriori_task
        #     except asyncio.CancelledError:
        #         pass

        # if self.data_import_task:
        #     self.data_import_task.cancel()
        #     try:
        #         await self.data_import_task
        #     except asyncio.CancelledError:
        #         logger.info("Data import task cancelled")

        logger.info("Background tasks stopped successfully")

    async def _periodic_apriori_generation(self):
        """Generate Apriori rules periodically based on configuration"""
        # Run immediately on startup (configurable delay)
        startup_delay = settings.APRIORI_STARTUP_DELAY_MINUTES * 60
        await asyncio.sleep(startup_delay)

        while self.is_running:
            try:
                logger.info("Starting scheduled Apriori rule generation...")
                await self._generate_apriori_rules()
                logger.info("Completed scheduled Apriori rule generation")

                # Wait for configured interval before next run
                interval_seconds = settings.APRIORI_GENERATION_INTERVAL_HOURS * 60 * 60
                await asyncio.sleep(interval_seconds)

            except asyncio.CancelledError:
                logger.info("Apriori generation task cancelled")
                break
            except Exception as e:
                logger.error(f"Error in periodic Apriori generation: {e}")
                # Wait configured retry time before retrying on error
                retry_delay = settings.APRIORI_ERROR_RETRY_MINUTES * 60
                await asyncio.sleep(retry_delay)

    async def _generate_apriori_rules(self):
        """Generate Apriori rules in background thread"""

        def _sync_generate():
            db = SessionLocal()
            try:
                prediction_service = PredictionService(db)
                stats = prediction_service.generate_all_rules()
                logger.info(
                    f"Generated rules for {stats['households_processed']} households, "
                    f"total {stats['total_rules_generated']} rules"
                )
                return stats
            finally:
                db.close()

        # Run in thread pool to avoid blocking async loop
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, _sync_generate)

    async def _periodic_data_import(self):
        """Import data periodically"""
        # Wait on startup to allow system initialization
        startup_delay = settings.DATA_IMPORT_STARTUP_DELAY_MINUTES * 60
        await asyncio.sleep(startup_delay)

        while self.is_running:
            try:
                logger.info("Starting scheduled data import...")
                await self._import_data()
                logger.info("Completed scheduled data import")

                # Wait before next run
                interval_seconds = settings.DATA_IMPORT_INTERVAL_HOURS * 60 * 60
                await asyncio.sleep(interval_seconds)

            except asyncio.CancelledError:
                logger.info("Data import task cancelled")
                break
            except Exception as e:
                logger.error(f"Error in periodic data import: {e}")
                # Wait before retrying on error
                retry_delay = settings.DATA_IMPORT_ERROR_RETRY_MINUTES * 60
                await asyncio.sleep(retry_delay)

    async def _import_data(self):
        """Import data in background thread"""

        def _sync_import():
            try:
                data_import_service = DataImportService()
                # Use asyncio.run to handle the async method in thread
                import asyncio

                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                try:
                    result = loop.run_until_complete(
                        data_import_service.import_all_chains()
                    )
                    logger.info(f"Data import completed: {result}")
                    return result
                finally:
                    loop.close()
            except Exception as e:
                logger.error(f"Data import failed: {e}")
                return {"error": str(e)}

        # Run in thread pool to avoid blocking async loop
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, _sync_import)


# Global instance
background_tasks = BackgroundTaskService()
