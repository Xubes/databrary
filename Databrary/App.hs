module Databrary.App
  ( application
  ) where

import Network.Wai (Application)

import Databrary.Service
import Databrary.Action
import Databrary.Routes

application :: Service -> Application
application = runAppRoute routes