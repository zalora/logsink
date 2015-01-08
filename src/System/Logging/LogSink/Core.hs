module System.Logging.LogSink.Core (
  Format
, defaultFormat
, stdErrSink
, sysLogSink
, combine
, filterByLogLevel
) where

import           Control.Monad
import           System.IO
import           System.Posix.Syslog
import           System.Logging.Facade.Types
import           System.Logging.Facade.Sink

import           System.Logging.LogSink.Format

defaultFormat :: Format
defaultFormat =
  let Right format = parseFormat defaultFormatString
  in format

stdErrSink :: Format -> LogSink
stdErrSink format record = format record >>= hPutStrLn stderr

sysLogSink :: Format -> LogSink
sysLogSink format record = format record >>= syslog (toPriority $ logRecordLevel record)
  where
    toPriority :: LogLevel -> Priority
    toPriority l = case l of
      TRACE -> Debug
      DEBUG -> Debug
      INFO -> Info
      WARN -> Warning
      ERROR -> Error

combine :: [LogSink] -> LogSink
combine sinks record = do
  forM_ sinks $ \sink -> sink record

filterByLogLevel :: LogLevel -> LogSink -> LogSink
filterByLogLevel level sink
  | level == minBound = sink
  | otherwise = filteringSink
  where
    filteringSink record
      | logRecordLevel record < level = return ()
      | otherwise = sink record
