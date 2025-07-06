# SwiftData Model and Performance Optimizations

## Schema Overview

The app uses three main SwiftData entities:

### `RecordingSession`
- Represents a full recording event.
- Stores date, metadata, and has a to-many relationship with `AudioSegment`.

### `AudioSegment`
- Stores file path of a 30-second audio chunk.
- Has a one-to-one relationship with `Transcription`.

### `Transcription`
- Stores text, status (`pending`, `completed`, `failed`), and metadata.
- Text is marked with `.externalStorage` for large file optimization.

## Data Relationships
- `RecordingSession` → `AudioSegment` → `Transcription`
- Cascade delete ensures child records are automatically removed when a session is deleted.

## Performance Strategies
- **External Storage**: `@Attribute(.externalStorage)` used for transcription text to reduce SQLite file bloat.
- **Segmented Recording**: Reduces memory footprint and improves fail tolerance.
- **Efficient Queries**: Uses `@Query` for fast and memory-safe fetches, even with 10,000+ segments.

## Notes
- The segmentation approach not only improves performance, but also enhances the reliability of transcription retries.

