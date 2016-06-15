import Data.List
import Graphics.Rendering.Cairo
import System.IO

w :: Int
w = 800

h :: Int
h = 800

cellw = 4
cellh = 4
cols = w `div` 4

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
              -- drawCells 0 0 (rle contents)


-- drawCells :: Int -> Int -> [(Int, Int)] -> IO ()
--           rectangle 0 0 100 100
--          fill

splitRLE n col ((count, v):(xs))
  | col'+count <= n = ((count, v):(splitRLE n (col'+count) xs))
  | otherwise = (remaining,v):(splitRLE n 0 ((count-remaining, v):xs))
  where col' = col `mod` n
        remaining = n - col'

rle :: Eq a => [a] -> [(Int, a)]
rle = map (\x -> (length x, head x)) . group
