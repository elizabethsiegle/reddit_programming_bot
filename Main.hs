{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE PatternGuards #-}
{-# OPTIONS_GHC -fno-warn-deprecations #-}

module Main where

import System.IO
import Data.ByteString.Lazy.Char8
import Data.ByteString.Lazy.Char8()
import GHC.Types (IO (..))
import Control.Monad
import Control.Monad.IO.Class
import Data.Char(toUpper)
import Data.Maybe
import Data.Monoid ((<>))
import Data.Bool
import Prelude
import Network.HTTP.Client.TLS (getGlobalManager, tlsManagerSettings)
import Network.HTTP.Client
import Network.Linklater
import Control.Monad.Trans.Maybe
import Data.Aeson
import Servant.Common.Req
import System.Random
import Control.Monad.Random hiding (Random)

import qualified Data.Text as T
import qualified Data.Text.IO as T 
import           Control.Monad.IO.Class (liftIO)
import           Control.Monad.Trans.Maybe (MaybeT, runMaybeT)
import           Data.Aeson (encode)
import           Data.Text (Text)
import Network.HTTP.Types
import Network.TLS
import Network.Wai.Handler.Warp (run)
import Network.Wreq

import Network.HTTP.Types.Status (statusCode)
import Network.HTTP.Base

import Reddit
import Reddit.Types.Post
import Reddit.Types.SearchOptions (Order (..))
--import Web.Google.Translate
import Control.Monad
import Control.Monad.IO.Class
import qualified Data.Text as Text
import qualified Data.Text.IO as Text

randIntHelper:: Int -> Int
randIntHelper x = 2 * x

readSlackFile :: FilePath -> IO Text
readSlackFile filename =
  T.filter (/= '\n') . T.pack <$> Prelude.readFile filename

configIO :: IO Config
configIO =
  Config <$> (readSlackFile "hook")

parseText :: Text -> Maybe Text
parseText text = case T.strip text of
  "" -> Nothing
  x -> Just x

liftMaybe :: Maybe a -> IO a
liftMaybe = maybe mzero return

printPost :: Post -> T.Text
printPost post = do
  title post <> "\n" <> (T.pack . show . created $ post) <> "\n" <> "http://reddit.com"<> permalink post <> "\n" <> "Score: " <> (T.pack . show . score $ post)

findQPosts:: Text -> RedditT IO PostListing
findQPosts c = search (Just $ R "programming") (Options Nothing (Just 0)) Hot c

messageOfCommandReddit :: Command -> IO Network.Linklater.Message
messageOfCommandReddit (Command "reddit" user channel (Just text)) = do
  query <- liftMaybe (parseText text)
  posts <- runRedditAnon (findQPosts query)
  --num <- randomIO :: IO Int
  case posts of
    Right posts' ->
       return (messageOf [FormatAt user, FormatString (T.intercalate "\n\n". Prelude.map printPost $ contents posts')]) where
        messageOf =
          FormattedMessage(EmojiIcon "gift") "redditbot" channel
          

redditify :: Maybe Command -> IO Text
redditify Nothing =
  return "Unrecognized Slack request!"

redditify(Just command) = do
  Prelude.putStrLn ("+ Incoming command: " <> show command)
  message <- (messageOfCommandReddit) command
  config <- configIO
  --putStrLn ("+ Outgoing message: " <> show (message))
  case (debug, message) of
    (False,  m) -> do
      _ <- say m config
      return ""
    --(False, Nothing) ->
    --  return "ugh"
    _ ->
      return ""
  where
    debug = False

--messageOfCommandHackerNews :: Command -> IO Network.Linklater.Message
--messageOfCommandHackerNews (Command "hackernews" user channel (Just text)) = do
--  mgr <- newManager tlsManagerSettings
--  case mgr of
--    Right (getTopStories mgr) ->
--    return (messageOf [FormatAt user, FormatString (getTopStories mgr)])
--      where 
--        messageOf =
--          FormattedMessage(EmojiIcon "gift") "hackernews" channel

--hnify:: Maybe Command -> IO Text
--hnify Nothing = 
--  return "Unrecognized Slack request"

--hnify (Just command) = do
--  Prelude.putStrLn ("+ Incoming command: " <> show command)
--  message <- (messageOfCommandHackerNews) command
--  config <- configIO
--  --putStrLn ("+ Outgoing message: " <> show (message))
--  case (debug, message) of
--    (False,  m) -> do
--      _ <- say m config
--      return ""
--    --(False, Nothing) ->
--    --  return "ugh"
--    _ ->
--      return ""
--  where
--    debug = False

main :: IO ()
main = do
  Prelude.putStrLn ("+ Listening on port " <> show port)
  run port (slashSimple redditify)
    where
      port = 3000