{-# LANGUAGE DeriveDataTypeable #-}

module Sphere where

import Data.Data
import Text.JSON.Generic

data Sphere = Sphere {
    distance :: Float, -- km
    period :: Float,   -- Days
    mass :: Float      -- kg
  } deriving (Typeable, Data, Show, Eq, Ord)
