module Sound.Tidal.WebSocket where

import Control.Exception (try)
import qualified Sound.Tidal.Context as Tidal
import qualified Sound.Tidal.Stream as Tidal
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified Network.WebSockets as WS
import Data.List
import Data.Ratio

import Request
import Sound.Tidal.Hint

type TidalState = (Tidal.ParamPattern -> IO(), [ParamPattern])

port = 9162

main = do
  putStrLn "TidalCycles websocket server, listening on port " ++ show 9162
  mPatterns <- newMVar []
  WS.runServer "0.0.0.0" port $ (\pending -> do
    conn <- WS.acceptRequest pending
        putStrLn "received new connection"
    WS.forkPingThread conn 30
    d <- Tidal.dirtStream
    loop (d, mPatterns) conn
    )

loop :: TidalState -> WS.Connection -> IO ()
loop state@(d, mPatterns) conn = do
  msg <- try (WS.receiveData conn)
  -- add to dictionary of connections -> patterns, could use a map for this
  modifyMVar_ mPatterns (return . ((conn, silence):))
  
  case msg of
    Right s -> do
      r <- act state (T.unpack s)
      case y of Just z -> WS.sendTextData conn (T.pack (encodeStrict z))
                Nothing -> return ()
      loop state conn
    Left WS.ConnectionClosed -> close state "unexpected loss of connection"
    Left (WS.CloseRequest _ _) -> close state "by request from peer"
    Left (WS.ParseException e) -> close state ("parse exception: " ++ e)

close :: TidalState -> String -> IO ()
close (cps,dss) msg = do
  putStrLn ("connection closed: " ++ msg)
  hush dss

hush = mapM_ ($ Tidal.silence)

act :: TidalState -> Result Request -> IO (Response)
act state request = do
  putStrLn (show request)

processRequest :: TidalState -> Request -> IO (Maybe String)

processRequest _ (Info i) = return Nothing

processRequest (_,dss) Hush = do
  hush dss
  return Nothing

processRequest (cps,_) (Cps x) = do
  cps x
  return Nothing

processRequest (_,dss) (Pattern n p) = do
  x <- hintParamPattern p
  case x of (Left error) -> do
              putStrLn "Error interpreting pattern"
              return Nothing
            (Right paramPattern) -> do
              dss!!(n-1) $ paramPattern
              return Nothing

processRequest _ (Render patt cps cycles) = do
  x <- hintParamPattern patt
  case x of (Left error) -> do
              putStrLn "Error interpreting pattern"
              return Nothing
            (Right paramPattern) -> do
              let r = render paramPattern cps cycles
              putStrLn (encodeStrict r)
              return (Just (showJSON r))
