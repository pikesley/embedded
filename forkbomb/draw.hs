import Data.List
import Graphics.Rendering.Cairo
import System.IO

w :: Int
w = 800

h :: Int
h = 800

cellw = 4
cellh = 4
cols = w `div` cellw

main = do handle <- openFile "10.txt" ReadMode
          contents <- hGetContents handle
          hClose handle
          withPDFSurface "test.pdf" (fromIntegral w) (fromIntegral h) $ \surf -> do
            renderWith surf $ do
              setOperator OperatorOver
              setSourceRGB 1 1 1
              rectangle 0 0 (fromIntegral w) (fromIntegral h)
              fill
              setSourceRGB 0 0 0
              let things = rleXY cols contents
              mapM_ drawThing things
              return ()

drawThing (x,y,len,v) = do rectangle (x+(fromIntegral cellw)) (y+(fromIntegral cellh)) (cellw*(fromIntegral len)) cellh
                           fill
                           return ()


-- drawCells :: Int -> Int -> [(Int, Int)] -> IO ()
--           rectangle 0 0 100 100
--          fill

rleXY :: Eq a => Int -> [a] -> [(Int, Int, Int, a)]
rleXY n xs = toXY 0 $ splitRLE n 0 $ rle xs
  where toXY _ [] = []
        toXY i ((col,v):xs) = (i `mod` n, i `div` n, col, v):(toXY (i+col) xs)

splitRLE _ _ [] = []
splitRLE n col ((count, v):(xs))
  | col'+count <= n = ((count, v):(splitRLE n (col'+count) xs))
  | otherwise = (remaining,v):(splitRLE n 0 ((count-remaining, v):xs))
  where col' = col `mod` n
        remaining = n - col'

rle :: Eq a => [a] -> [(Int, a)]
rle = map (\x -> (length x, head x)) . group
