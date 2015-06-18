{-# LANGUAGE OverloadedStrings, DeriveGeneric #-}

module Databrary.Search.Solr
( search,
  SolrResponse
) where

import Data.Int (Int32)
import Data.Aeson
import Data.Map
import Control.Applicative
import Control.Monad (mzero)
import GHC.Generics
import Network.HTTP.Types (hAccept, hContentType, ok200)
import System.Environment
import Databrary.HTTP.Client

import qualified Network.HTTP.Client as HC
import qualified Data.Attoparsec.ByteString as P
import qualified Data.ByteString as BS

import qualified Data.ByteString.Lazy.Char8 as L
import Control.Monad.IO.Class (liftIO)

import qualified Databrary.Search.Query as Q


solrServer = "http://localhost/solr/Databrary/query"
solrPort = 8983


newtype Params = Params (Map String String) deriving (Show)
instance FromJSON Params where
  parseJSON val = Params <$> parseJSON val

data ResponseHeader = ResponseHeader {
  status :: Int,
  qTime  :: Int,
  params :: Params
} deriving (Show)
instance FromJSON ResponseHeader where
  parseJSON (Object o) = ResponseHeader <$> o .: "status"
                                        <*> o .: "QTime"
                                        <*> o .: "params"
  parseJSON _ = mzero

data Docs = Docs {
   content_type :: String,
   id :: String,
   _version_ :: Maybe Int,
   volume_id_i :: Maybe Int,
   alias_s :: Maybe String,
   text_en :: Maybe [String],
   title_t :: Maybe String,
   citation_url_s :: Maybe String,
   citation_t :: Maybe String,
   citation_year_i :: Maybe Int,
   container_id_i :: Maybe Int,
   container_volume_id_i :: Maybe Int,
   container_date_tdt :: Maybe String,
   container_name_t :: Maybe String,
   container_age_td :: Maybe Double,
   container_keywords_ss :: Maybe [String],
   record_id_i :: Maybe Int,
   record_volume_id_i :: Maybe Int,
   record_container_i :: Maybe Int,
   record_date_tdt :: Maybe String,
   record_text_t :: Maybe String,
   record_num_d :: Maybe Double,
   segment_volume_id_i :: Maybe Int,
   segment_record_id_i :: Maybe Int,
   segment_container_id_i :: Maybe Int,
   segment_start_tl :: Maybe String,
   segment_end_tl :: Maybe String,
   segment_length_tl :: Maybe String,
   segment_tags_ss :: Maybe [String],
   segment_asset_i :: Maybe Int,
   segment_asset_name_s :: Maybe String,
   url :: Maybe String
} deriving (Show,Generic)
instance FromJSON Docs

data Results = Results {
  numFound :: Int,
  start :: Int,
  docs :: [Docs]
} deriving (Show)
instance FromJSON Results where
  parseJSON (Object o) = Results <$> o .: "numFound"
                                 <*> o .: "start"
                                 <*> o .: "docs"
  parseJSON _ = mzero

data SolrResponse = SolrResponse {
  responseHeader :: ResponseHeader,
  response :: Results
} deriving (Show)
instance FromJSON SolrResponse where
  parseJSON (Object o) = SolrResponse <$> o .: "responseHeader"
                                      <*> o .: "response"
  parseJSON _ = mzero

data SolrQuery = SolrQuery {
   solrQuery :: String,
   solrLimit :: Int32,
   solrStart :: Int32
} deriving (Show)
instance ToJSON SolrQuery where
      toJSON ( SolrQuery sQquery sQlimit sQstart ) =
         object [ "query" .= sQquery,
                  "limit" .= sQlimit,
                  "offset" .= sQstart ]

-- formQuery :: String -> SolrQuery
-- formQuery q = SolrQuery q

submitQuery :: HTTPClientM c m => HC.Request -> m (Maybe Value)
submitQuery q = httpRequestJSONSolr q

generatePostReq :: SolrQuery -> IO HC.Request
generatePostReq sr = do
      initReq <- HC.parseUrl solrServer
      let reqBody = HC.RequestBodyLBS $ encode sr
      let req = initReq {
                       HC.method = "POST",
                       HC.port = solrPort,
                       HC.requestBody = reqBody,
                       HC.requestHeaders = ("content-type", "application/json") : HC.requestHeaders initReq
                    }
      return req

httpRequestJSONSolr :: HTTPClientM c m => HC.Request -> m (Maybe Value)
httpRequestJSONSolr req = httpRequest req "text/plain" $ \rb ->
  P.maybeResult <$> P.parseWith rb json BS.empty

search :: HTTPClientM c m => String -> Int32 -> Int32 -> m (Maybe Value)
search q offset limit = do
      let query = Q.createQuery q
      let sQuery = SolrQuery (Q.queryToString query) limit offset
      request <- liftIO $ generatePostReq sQuery
      liftIO $ print sQuery -- TODO REMOVE THIS
      liftIO $ print q
      (submitQuery request)