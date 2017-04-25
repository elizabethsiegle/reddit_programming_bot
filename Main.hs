{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE PatternGuards #-}
{-# OPTIONS_GHC -fno-warn-deprecations #-}

-- If writing Slack bots intrigues you, check out: https://github.com/hlian/linklater

import qualified Data.Text as T
--import qualified Network.Images.Search as Search
import qualified Data.ByteString as B
import           Control.Monad.IO.Class (liftIO)
import           Control.Monad.Trans.Maybe (MaybeT, runMaybeT)
import           Data.Aeson (encode)
import           Data.Text (Text)
import Network.HTTP.Types
import Network.TLS
import Network.Wai
--import Network.Wai.Handler.Warp
--import Network.Wai.Handler.WarpTLS
--import           Network.Wai.Handler.Warp.Run 
import Control.Lens
import Network.Wreq
--import Data.Word8
import Data.Attoparsec
--import HTTP.Conduit
-- Naked imports.
import           BasePrelude hiding (words, intercalate)
import           Network.Linklater
--import Network.Wai.Handler.Warp
--import System.IO.UTF8

import Control.Monad.Trans.Class


import Network.HTTP.Client.TLS (getGlobalManager)
import Network.HTTP.Client
import Network.HTTP.Client.TLS

import Web.HackerNews
--import Network.HTTP.Types.Status (statusCode)
--import Network.HTTP.Base
import Servant.Client (ClientEnv(ClientEnv), runClientM)
import Web.Yahoo.Finance.YQL
--       (StockSymbol(StockSymbol), YQLQuery(YQLQuery), getQuotes,
--        yahooFinanceJsonBaseUrl)
--import Network.Yahoo.Finance


cleverlyReadFile :: FilePath -> IO Text
cleverlyReadFile filename =
  T.filter (/= '\n') . T.pack <$> readFile filename

configIO :: IO Config
configIO =
  Config <$> (cleverlyReadFile "hook")

--googleConfigIO :: IO Search.Gapi
--googleConfigIO =
--  Search.config <$> (cleverlyReadFile "google-server-key") <*> (cleverlyReadFile "google-search-engine-id")

parseText :: Text -> Maybe Text
parseText text = case T.strip text of
  "" -> Nothing
  x -> Just x

liftMaybe :: Maybe a -> MaybeT IO a
liftMaybe = maybe mzero return

messageOfCommand :: Command -> MaybeT IO Message

messageOfCommand (Command "stock" user channel (Just text)) = do
  --gapi <- liftIO googleConfigIO
  query <- liftMaybe (parseText text)
  --urls <- liftIO (Search.linksOfQuery gapi query)
  --url <- liftMaybe (listToMaybe urls)
  return (messageOf [FormatAt user, FormatLink query query])
  where
    messageOf =
      FormattedMessage (EmojiIcon "gift") "stockbot" channel
messageOfCommand _ =
  mzero

jpgto :: Maybe Command -> IO Text
jpgto Nothing =
  return "Unrecognized Slack request!"

jpgto (Just command) = do
  putStrLn ("+ Incoming command: " <> show command)
  manager <- getGlobalManager
  res <- runClientM (getQuotes (YQLQuery [StockSymbol res]) ) (ClientEnv manager yahooFinanceJsonBaseUrl)
  config <- configIO
  message <- (runMaybeT . messageOfCommand) res
  putStrLn ("+ Outgoing message: " <> (encode <$> res)) --message, !res
  case (debug, res) of
    (False, Just m) -> do
      _ <- say m config
      return ""
    (False, Nothing) ->
      return "ERROR PROCESSING INPUT"
    _ ->
      return ""
  where
    debug = False

main :: IO ()
main = do
  putStrLn ("+ Listening on port " <> show port)
  run port (slashSimple jpgto)
    where
      port = 3333