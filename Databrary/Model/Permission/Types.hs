{-# LANGUAGE OverloadedStrings, TemplateHaskell, QuasiQuotes, DeriveDataTypeable #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Databrary.Model.Permission.Types 
  ( Permission(..)
  , Consent(..)
  , Classification(..)
  , Access(..), accessPermission'
  , accessSite, accessMember, accessPermission
  ) where

import Data.Monoid (Monoid(..))
import Language.Haskell.TH.Lift (deriveLiftMany)

import Control.Has (Has(..))
import Databrary.DB (useTPG)
import Databrary.Model.Enum

useTPG

makeDBEnum "permission" "Permission"
makeDBEnum "consent" "Consent"
makeDBEnum "classification" "Classification"

deriveLiftMany [''Permission, ''Consent, ''Classification]

data Access = Access
  { accessSite' :: !Permission
  , accessMember' :: !Permission
  }

accessPermission' :: Access -> Permission
accessPermission' (Access s m) = min s m

accessSite, accessMember, accessPermission :: Has Access a => a -> Permission
accessSite = accessSite' . view
accessMember = accessMember' . view
accessPermission = accessPermission' . view

instance Bounded Access where
  minBound = Access minBound minBound
  maxBound = Access maxBound maxBound

instance Monoid Access where
  mempty = Access PermissionNONE PermissionNONE
  mappend (Access s1 m1) (Access s2 m2) = Access (max s1 s2) (max m1 m2)
