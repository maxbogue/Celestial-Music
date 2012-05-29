module Input where

import System.Environment (getArgs)
import Text.JSON.Generic (decodeJSON)
import Sphere 

readSpheres :: IO ([Sphere])
readSpheres = do
    args <- getArgs
    case args of
        []      -> error "bad arguments.\nUsage: CelestialMusic <input_file>"
        (arg:_) -> readFile arg >>= return . decodeJSON
