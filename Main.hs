import System.Environment (getArgs)

import Text.JSON.Generic
import Sphere 

readSpheres :: IO ([Sphere])
readSpheres = do
    args <- getArgs
    jsonText <- readFile $ head args
    return $ decodeJSON jsonText

main = do
    spheres <- readSpheres
    putStrLn $ show spheres
