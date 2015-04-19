{-# LANGUAGE TemplateHaskell #-}
module Databrary.Model.Consent
  ( module Databrary.Model.Consent.Types
  , changeConsent
  ) where

import Control.Applicative ((<$>))
import Control.Monad (guard)

import Databrary.Service.DB
import Databrary.Model.SQL
import Databrary.Model.Audit
import Databrary.Model.Slot.Types
import Databrary.Model.Container.Types
import Databrary.Model.Consent.Types
import Databrary.Model.Consent.SQL

useTPG

changeConsent :: MonadAudit c m => Slot -> Maybe Consent -> m Bool
changeConsent s Nothing = do
  ident <- getAuditIdentity
  dbExecute1 $(deleteConsent 'ident 's)
changeConsent s (Just c) = do
  ident <- getAuditIdentity
  either (const False) ((0 <) . fst) <$> tryUpdateOrInsert (guard . isExclusionViolation)
    $(updateConsent 'ident 's 'c)
    $(insertConsent 'ident 's 'c)
