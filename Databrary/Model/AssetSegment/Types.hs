module Databrary.Model.AssetSegment.Types
  ( AssetSegment(..)
  , newAssetSegment
  , assetFullSegment
  , assetSlotSegment
  , assetSegmentFull
  , assetSegmentRange
  , Excerpt(..)
  , newExcerpt
  , excerptInSegment
  ) where

import Data.Maybe (fromMaybe)
import qualified Database.PostgreSQL.Typed.Range as Range

import Databrary.Ops
import Databrary.Has (Has(..))
import Databrary.Model.Permission
import Databrary.Model.Offset
import Databrary.Model.Segment
import Databrary.Model.Id.Types
import Databrary.Model.Volume.Types
import Databrary.Model.Consent.Types
import Databrary.Model.Container.Types
import Databrary.Model.Slot.Types
import Databrary.Model.Format
import Databrary.Model.Asset.Types
import Databrary.Model.AssetSlot.Types

data AssetSegment = AssetSegment
  { segmentAsset :: AssetSlot
  , assetSegment :: !Segment
  , assetExcerpt :: Maybe Excerpt
  }

newAssetSegment :: AssetSlot -> Segment -> Maybe Excerpt -> AssetSegment
newAssetSegment a s e = AssetSegment a (view a `segmentIntersect` s) e

assetFullSegment :: AssetSegment -> AssetSegment
assetFullSegment AssetSegment{ assetExcerpt = Just e } = excerptFullSegment e
assetFullSegment AssetSegment{ segmentAsset = a } = newAssetSegment a fullSegment Nothing

-- |A "fake" (possibly invalid) 'AssetSegment' corresponding to the full 'AssetSlot'
assetSlotSegment :: AssetSlot -> AssetSegment
assetSlotSegment a = AssetSegment a (view a) Nothing

assetSegmentFull :: AssetSegment -> Bool
assetSegmentFull AssetSegment{ segmentAsset = a, assetSegment = s } = view a == s

assetSegmentRange :: AssetSegment -> Range.Range Offset
assetSegmentRange AssetSegment{ segmentAsset = a, assetSegment = Segment s } =
  fmap (\x -> x - fromMaybe 0 (lowerBound (segmentRange (view a)))) s

instance Has AssetSlot AssetSegment where
  view = segmentAsset
instance Has Asset AssetSegment where
  view = view . segmentAsset
instance Has (Id Asset) AssetSegment where
  view = view . segmentAsset
instance Has Volume AssetSegment where
  view = view . segmentAsset
instance Has (Id Volume) AssetSegment where
  view = view . segmentAsset

instance Has Slot AssetSegment where
  view AssetSegment{ segmentAsset = AssetSlot{ assetSlot = Just s }, assetSegment = seg } = s{ slotSegment = seg }
  view _ = error "unlinked AssetSegment"
instance Has Container AssetSegment where
  view = slotContainer . view
instance Has (Id Container) AssetSegment where
  view = containerId . slotContainer . view
instance Has Segment AssetSegment where
  view AssetSegment{ segmentAsset = AssetSlot{ assetSlot = Just s }, assetSegment = seg } = seg `segmentIntersect` slotSegment s
  view _ = emptySegment
instance Has (Maybe Consent) AssetSegment where
  view = view . (view :: AssetSegment -> Slot)

instance Has Format AssetSegment where
  view AssetSegment{ segmentAsset = a, assetSegment = Segment rng }
    | Just s <- formatSample fmt
    , Just _ <- Range.getPoint rng = s
    | otherwise = fmt
    where fmt = view a
instance Has (Id Format) AssetSegment where
  view = formatId . view
instance Has Classification AssetSegment where
  view AssetSegment{ assetExcerpt = Just e } = view e
  view AssetSegment{ segmentAsset = a } = view a

instance Has Permission AssetSegment where
  view a = dataPermission (view $ segmentAsset a) (view a) (view a)


data Excerpt = Excerpt
  { excerptAsset :: !AssetSegment
  , excerptClassification :: !Classification
  }

newExcerpt :: AssetSlot -> Segment -> Classification -> Excerpt
newExcerpt a s c = e where 
  as = newAssetSegment a s (Just e)
  e = Excerpt as c

excerptInSegment :: Excerpt -> Segment -> AssetSegment
excerptInSegment e@Excerpt{ excerptAsset = AssetSegment{ segmentAsset = a, assetSegment = es } } s 
  | segmentOverlaps es s = as
  | otherwise = error "excerptInSegment: non-overlapping"
  where as = newAssetSegment a s (es `segmentContains` assetSegment as ?> e)

excerptFullSegment :: Excerpt -> AssetSegment
excerptFullSegment e = excerptInSegment e fullSegment

instance Has AssetSegment Excerpt where
  view = excerptAsset
instance Has AssetSlot Excerpt where
  view = view . excerptAsset
instance Has Asset Excerpt where
  view = view . excerptAsset
instance Has (Id Asset) Excerpt where
  view = view . excerptAsset
instance Has Volume Excerpt where
  view = view . excerptAsset
instance Has (Id Volume) Excerpt where
  view = view . excerptAsset
instance Has Slot Excerpt where
  view = view . excerptAsset
instance Has Container Excerpt where
  view = view . excerptAsset
instance Has (Id Container) Excerpt where
  view = view . excerptAsset
instance Has Segment Excerpt where
  view = view . excerptAsset
instance Has (Maybe Consent) Excerpt where
  view = view . excerptAsset
instance Has Permission Excerpt where
  view = view . excerptAsset

instance Has Classification Excerpt where
  view = excerptClassification