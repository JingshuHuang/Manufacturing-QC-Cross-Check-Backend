import logging
from typing import Dict, Any, Optional
from pathlib import Path
from sqlalchemy.orm import Session

from app.models.file import UploadedFile, FileType, ProcessingStatus
from app.services.pdf_extractor import PDFExtractor
from app.services.ocr_service import OCRService
from app.services.excel_parser import ExcelParser

logger = logging.getLogger(__name__)


class FileProcessor:
    """Main service for orchestrating file processing"""
    
    def __init__(self):
        self.logger = logger
        self.pdf_extractor = PDFExtractor()
        self.ocr_service = OCRService()
        self.excel_parser = ExcelParser()
    
    def process_file(self, file_record: UploadedFile, db: Session) -> Dict[str, Any]:
        """Process a single file based on its type"""
        try:
            self.logger.info(f'Starting processing for file: {file_record.filename} ({file_record.file_type})')
            
            # Update status to processing
            file_record.processing_status = ProcessingStatus.PROCESSING
            db.commit()
            
            # Process based on file type
            if file_record.file_type == FileType.TRAVELER_PDF:
                result = self.pdf_extractor.extract_traveler_data(file_record.file_path)
            elif file_record.file_type == FileType.PRODUCT_IMAGE:
                result = self.ocr_service.extract_product_image_data(file_record.file_path)
            elif file_record.file_type == FileType.BOM_EXCEL:
                result = self.excel_parser.parse_bom_file(file_record.file_path)
            else:
                result = {
                    'success': False,
                    'error': f'Unsupported file type: {file_record.file_type}'
                }
            
            # Update file record with results
            if result['success']:
                file_record.extracted_data = result
                file_record.processing_status = ProcessingStatus.COMPLETED
                self.logger.info(f'Successfully processed file: {file_record.filename}')
            else:
                file_record.processing_error = result.get('error', 'Unknown error')
                file_record.processing_status = ProcessingStatus.FAILED
                self.logger.error(f'Failed to process file {file_record.filename}: {result.get("error")}')
            
            db.commit()
            return result
            
        except Exception as e:
            self.logger.error(f'File processing error for {file_record.filename}: {str(e)}')
            
            # Update status to failed
            try:
                file_record.processing_error = str(e)
                file_record.processing_status = ProcessingStatus.FAILED
                db.commit()
            except Exception as db_error:
                self.logger.error(f'Failed to update file status: {str(db_error)}')
            
            return {
                'success': False,
                'error': str(e)
            }
    
    def process_session_files(self, session_id: str, db: Session) -> Dict[str, Any]:
        """Process all files in a session"""
        try:
            # Get all pending files for the session
            files = db.query(UploadedFile).filter(
                UploadedFile.session_id == session_id,
                UploadedFile.processing_status == ProcessingStatus.PENDING
            ).all()
            
            if not files:
                return {
                    'success': True,
                    'message': 'No files to process',
                    'processed_count': 0
                }
            
            results = []
            successful_count = 0
            failed_count = 0
            
            for file_record in files:
                result = self.process_file(file_record, db)
                results.append({
                    'file_id': str(file_record.id),
                    'filename': file_record.filename,
                    'file_type': file_record.file_type,
                    'success': result['success'],
                    'error': result.get('error')
                })
                
                if result['success']:
                    successful_count += 1
                else:
                    failed_count += 1
            
            return {
                'success': True,
                'processed_count': len(files),
                'successful_count': successful_count,
                'failed_count': failed_count,
                'results': results
            }
            
        except Exception as e:
            self.logger.error(f'Session file processing error for session {session_id}: {str(e)}')
            return {
                'success': False,
                'error': str(e)
            }
    
    def validate_file(self, file_path: str, file_type: FileType) -> Dict[str, Any]:
        """Validate a file before processing"""
        try:
            if not Path(file_path).exists():
                return {
                    'valid': False,
                    'error': 'File does not exist'
                }
            
            # Validate based on file type
            if file_type == FileType.TRAVELER_PDF:
                return self.pdf_extractor.validate_pdf(file_path)
            elif file_type == FileType.PRODUCT_IMAGE:
                return self.ocr_service.validate_image(file_path)
            elif file_type == FileType.BOM_EXCEL:
                return self.excel_parser.validate_excel_file(file_path)
            else:
                return {
                    'valid': False,
                    'error': f'Unsupported file type: {file_type}'
                }
                
        except Exception as e:
            return {
                'valid': False,
                'error': f'File validation failed: {str(e)}'
            }
    
    def get_processing_summary(self, session_id: str, db: Session) -> Dict[str, Any]:
        """Get processing summary for a session"""
        try:
            files = db.query(UploadedFile).filter(
                UploadedFile.session_id == session_id
            ).all()
            
            if not files:
                return {
                    'total_files': 0,
                    'by_status': {},
                    'by_type': {}
                }
            
            status_counts = {}
            type_counts = {}
            
            for file_record in files:
                # Count by status
                status = file_record.processing_status.value
                status_counts[status] = status_counts.get(status, 0) + 1
                
                # Count by type
                file_type = file_record.file_type.value
                type_counts[file_type] = type_counts.get(file_type, 0) + 1
            
            return {
                'total_files': len(files),
                'by_status': status_counts,
                'by_type': type_counts,
                'files': [
                    {
                        'id': str(f.id),
                        'filename': f.filename,
                        'file_type': f.file_type.value,
                        'processing_status': f.processing_status.value,
                        'has_extracted_data': f.extracted_data is not None,
                        'processing_error': f.processing_error
                    }
                    for f in files
                ]
            }
            
        except Exception as e:
            self.logger.error(f'Failed to get processing summary for session {session_id}: {str(e)}')
            return {
                'error': str(e)
            }
