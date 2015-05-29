{-# LANGUAGE OverloadedStrings #-}
module Databrary.Controller.Tag
  ( queryTags
  , postTag
  , deleteTag
  , viewTopTags
  ) where

import qualified Data.Text as T
import Network.HTTP.Types (StdMethod(DELETE), conflict409)

import Databrary.JSON (toJSON)
import Databrary.Model.Permission
import Databrary.Model.Id
import Databrary.Model.Slot
import Databrary.Model.Tag
import Databrary.HTTP.Form.Deform
import Databrary.HTTP.Path.Parser
import Databrary.Action
import Databrary.Controller.Paths
import Databrary.Controller.Permission
import Databrary.Controller.Slot

_tagNameForm :: (Functor m, Monad m) => DeformT m TagName
_tagNameForm = deformMaybe' "Invalid tag name." . validateTag =<< deform

queryTags :: AppRoute TagName
queryTags = action GET (pathJSON >/> "tags" >/> PathDynamic) $ \t ->
  okResponse [] . toJSON . map tagId =<< findTags t

postTag :: AppRoute (API, Id Slot, TagId)
postTag = action POST (pathAPI </>> pathSlotId </> pathTagId) $ \(api, si, TagId kw tn) -> withAuth $ do
  u <- authAccount
  s <- getSlot (if kw then PermissionEDIT else PermissionSHARED) Nothing si
  t <- addTag tn
  r <- addTagUse $ TagUse t kw u s
  guardAction r $ 
    returnResponse conflict409 [] ("The requested tag overlaps your existing tag." :: T.Text)
  okResponse [] ("" :: T.Text)

deleteTag :: AppRoute (API, Id Slot, TagId)
deleteTag = action DELETE (pathAPI </>> pathSlotId </> pathTagId) $ \(api, si, TagId kw tn) -> withAuth $ do
  u <- authAccount
  s <- getSlot (if kw then PermissionEDIT else PermissionSHARED) Nothing si
  _r <- maybe (return False) (\t -> removeTagUse $ TagUse t kw u s) =<< lookupTag tn
  okResponse [] ("" :: T.Text)

viewTopTags :: AppRoute ()
viewTopTags = action GET (pathJSON >/> "tags") $ \() -> do
  l <- lookupTopTagWeight 16
  okResponse [] $ toJSON $ map tagWeightJSON l