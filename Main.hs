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

--slack bots: auto site testing, news, phone call, see social
-- media info about people, send screenshots to GitHub, Trello,
-- etc,time tracking/allocating, shop, find apps, more

-- slack commands: mute/unmute channel, set reminders, list
-- users, priv. msg, send/search gifs, search google imgs
-- = used to increase productivity, access apps/news/etc
-- from within Slack, automate tasks
-- use bot when user involved in process (approval, q+a)

--ngrok creates secure public URL (https://yourapp.ngrok.io) 
--to local webserver on your machine.
--Inspect HTTP traffic flowing over your tunnel. Then, replay
--webhook reqs w/ 1 click 2 iterate quickly while staying in context.

--readSlackFile* reads in an incoming Slack webhook letting 
--external sources (in this case, the bot) post messages into 
--Slack. It uses normal HTTP requests with a JSON payload 
--including the message text, but there are additional options, too. 

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

-- printPost* formats the Reddit post, converting it into 
--Text and creating an external link to take you to the 
--trending Reddit post. 
printPost :: Post -> T.Text
printPost post = do
  title post <> "\n" <> (T.pack . show . created $ post) <> "\n" <> "http://reddit.com"<> permalink post <> "\n" <> "Score: " <> (T.pack . show . score $ post)

--searches for Hot programming posts given input (ie haskell)
findQPosts:: Text -> RedditT IO PostListing
findQPosts c = search (Just $ R "programming") (Options Nothing (Just 0)) Hot c

--gets Reddit posts, and creates the message that will be 
--posted to Slack. 
messageOfCommandReddit :: Command -> IO Network.Linklater.Message
messageOfCommandReddit (Command "reddit" user channel (Just text)) = do
  query <- liftMaybe (parseText text)
  posts <- runRedditAnon (findQPosts query)
  case posts of
    Right posts' ->
       return (messageOf [FormatAt user, FormatString (T.intercalate "\n\n". Prelude.map printPost $ contents posts')]) where
        messageOf =
          FormattedMessage(EmojiIcon "gift") "redditbot" channel
          
--calls *messageOfCommandReddit*, which actually posts the 
--message to Slack after running *stack build*, then *stack 
--exec redditbot*, and then opening up a Ngrok tunnel at the same port.
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
    _ ->
      return ""
  where
    debug = False

main :: IO ()
main = do
  Prelude.putStrLn ("+ Listening on port " <> show port)
  run port (slashSimple redditify)
    where
      port = 3000