{-# LANGUAGE OverloadedStrings, TemplateHaskell, TypeFamilies #-}
module Databrary.Model.Container.Types
  ( Container(..)
  , MonadHasContainer
  ) where

import qualified Data.Text as T

import Control.Has (makeHasRec)
import Databrary.Time
import Databrary.Model.Kind
import Databrary.Model.Permission.Types
import Databrary.Model.Id.Types
import Databrary.Model.Volume.Types

type instance IdType Container = Int32

data Container = Container
  { containerId :: Id Container
  , containerTop :: Bool
  , containerName :: Maybe T.Text
  , containerDate :: Maybe Date
  , containerConsent :: Maybe Consent
  , containerVolume :: Volume
  }

instance Kinded Container where
  kindOf _ = "slot"

makeHasRec ''Container ['containerId, 'containerConsent, 'containerVolume]