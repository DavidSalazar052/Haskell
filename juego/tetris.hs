
--  .\tetris.exe    -- comando para correr el juego


-- tetris.hs
-- Tetris para la terminal, hecho solo con la libreria base de Haskell.
--
-- Compilar:  ghc -o tetris tetris.hs
-- Jugar:     .\tetris            (las piezas caen solas)
--            .\tetris turnos     (modo por turnos: cae una fila por tecla)
--
-- Teclas:  a = izquierda   d = derecha   w = girar
--          s = bajar       ESPACIO = caida rapida      q = salir

{-# LANGUAGE ForeignFunctionInterface #-}
module Main where

import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.Chan (Chan, newChan, readChan, writeChan)
import Control.Exception (finally)
import Data.Char (chr, toLower)
import Foreign.C.Types (CInt (..))
import Data.Maybe (isNothing)
import GHC.Clock (getMonotonicTime, getMonotonicTimeNSec)
import System.Environment (getArgs)
import System.IO
import System.Timeout (timeout)

-- ------------------------------------------------------------
-- Tipos de datos
-- ------------------------------------------------------------

filas, columnas :: Int
filas    = 20
columnas = 10

-- Las 7 piezas del Tetris: un tipo de dato algebraico
data Pieza = I | O | T | S | Z | J | L
  deriving (Show, Eq, Enum, Bounded)

type Celda   = (Int, Int)            -- (fila, columna)
type Tablero = [[Maybe Pieza]]       -- Nothing = vacio, Just p = ocupado por p

-- La pieza que cae: su tipo, sus celdas relativas y su posicion
data Activa = Activa
  { pieza     :: Pieza
  , relativas :: [Celda]
  , posF      :: Int
  , posC      :: Int
  }

-- Todo el estado del juego. Nada se modifica: cada accion crea un Juego nuevo.
data Juego = Juego
  { tablero   :: Tablero
  , activa    :: Activa
  , siguiente :: Pieza
  , semilla   :: Int
  , puntos    :: Int
  , lineas    :: Int
  , terminado :: Bool
  }

-- ------------------------------------------------------------
-- Piezas
-- ------------------------------------------------------------

forma :: Pieza -> [Celda]
forma I = [(0,-1), (0,0), (0,1), (0,2)]
forma O = [(0,0), (0,1), (1,0), (1,1)]
forma T = [(0,0), (1,-1), (1,0), (1,1)]
forma S = [(0,0), (0,1), (1,-1), (1,0)]
forma Z = [(0,-1), (0,0), (1,0), (1,1)]
forma J = [(0,-1), (1,-1), (1,0), (1,1)]
forma L = [(0,1), (1,-1), (1,0), (1,1)]

-- Gira 90 grados a la derecha (el cuadrado O no cambia)
girar :: Pieza -> [Celda] -> [Celda]
girar O cs = cs
girar _ cs = [(c, negate r) | (r, c) <- cs]

nueva :: Pieza -> Activa
nueva p = Activa p (forma p) 0 (columnas `div` 2 - 1)

celdas :: Activa -> [Celda]
celdas a = [(r + posF a, c + posC a) | (r, c) <- relativas a]

-- Generador de numeros pseudoaleatorios (congruencial lineal)
aleatoria :: Int -> (Pieza, Int)
aleatoria s = (toEnum (siguienteS `div` 65536 `mod` 7), siguienteS)
  where
    siguienteS = (s * 1103515245 + 12345) `mod` 2147483648

-- ------------------------------------------------------------
-- Tablero y reglas
-- ------------------------------------------------------------

filaVacia :: [Maybe Pieza]
filaVacia = replicate columnas Nothing

tableroVacio :: Tablero
tableroVacio = replicate filas filaVacia

libre :: Tablero -> Celda -> Bool
libre t (r, c) =
  r >= 0 && r < filas && c >= 0 && c < columnas && isNothing (t !! r !! c)

cabe :: Tablero -> Activa -> Bool
cabe t a = all (libre t) (celdas a)

desplazar :: Int -> Int -> Activa -> Activa
desplazar df dc a = a { posF = posF a + df, posC = posC a + dc }

poner :: Int -> Int -> Pieza -> Tablero -> Tablero
poner r c p t =
  [ [ if (i, k) == (r, c) then Just p else x | (k, x) <- zip [0 ..] fila ]
  | (i, fila) <- zip [0 ..] t ]

-- Quita las filas completas y cuenta cuantas eran
limpiar :: Tablero -> (Tablero, Int)
limpiar t = (replicate n filaVacia ++ restantes, n)
  where
    restantes = filter (any isNothing) t
    n         = length t - length restantes

premio :: Int -> Int
premio 0 = 0
premio 1 = 100
premio 2 = 300
premio 3 = 500
premio _ = 800

nivel :: Juego -> Int
nivel j = lineas j `div` 10 + 1

-- Segundos entre cada caida automatica: baja con el nivel
retardo :: Juego -> Double
retardo j = max 0.08 (0.8 - 0.07 * fromIntegral (nivel j - 1))

-- ------------------------------------------------------------
-- Acciones del jugador (todas devuelven un Juego nuevo)
-- ------------------------------------------------------------

moverLado :: Int -> Juego -> Juego
moverLado dc j
  | cabe (tablero j) a' = j { activa = a' }
  | otherwise           = j
  where
    a' = desplazar 0 dc (activa j)

-- Al girar prueba pequenos desplazamientos si la pieza choca con la pared
rotar :: Juego -> Juego
rotar j =
  case [b | (df, dc) <- patadas, let b = desplazar df dc girada, cabe (tablero j) b] of
    (b : _) -> j { activa = b }
    []      -> j
  where
    a       = activa j
    girada  = a { relativas = girar (pieza a) (relativas a) }
    patadas = [(0,0), (0,-1), (0,1), (0,-2), (0,2), (1,0)]

-- Baja una fila; si no puede, fija la pieza en el tablero
bajar :: Juego -> Juego
bajar j
  | cabe (tablero j) a' = j { activa = a' }
  | otherwise           = fijar j
  where
    a' = desplazar 1 0 (activa j)

-- Caida rapida: baja hasta el fondo (recursion)
caidaRapida :: Juego -> Juego
caidaRapida j
  | cabe (tablero j) a' = caidaRapida j { activa = a', puntos = puntos j + 2 }
  | otherwise           = fijar j
  where
    a' = desplazar 1 0 (activa j)

fijar :: Juego -> Juego
fijar j = j
  { tablero   = t2
  , activa    = proxima
  , siguiente = nuevaPieza
  , semilla   = nuevaSemilla
  , puntos    = puntos j + premio n * nivel j
  , lineas    = lineas j + n
  , terminado = not (cabe t2 proxima)
  }
  where
    a                        = activa j
    t1                       = foldr (\(r, c) t -> poner r c (pieza a) t)
                                     (tablero j) (celdas a)
    (t2, n)                  = limpiar t1
    proxima                  = nueva (siguiente j)
    (nuevaPieza, nuevaSemilla) = aleatoria (semilla j)

-- Traduce una tecla en una accion
aplicar :: Char -> Juego -> Juego
aplicar 'a' = moverLado (-1)
aplicar 'd' = moverLado 1
aplicar 'w' = rotar
aplicar 's' = bajar
aplicar ' ' = caidaRapida
aplicar _   = id

-- ------------------------------------------------------------
-- Dibujo en la terminal (con colores ANSI)
-- ------------------------------------------------------------

colorDe :: Pieza -> Int
colorDe I = 46
colorDe O = 43
colorDe T = 45
colorDe S = 42
colorDe Z = 41
colorDe J = 44
colorDe L = 47

bloque :: Pieza -> String
bloque p = "\ESC[" ++ show (colorDe p) ++ "m  \ESC[0m"

-- Donde caeria la pieza si se suelta ahora (la "sombra")
sombra :: Juego -> Activa
sombra j = bajarHasta (activa j)
  where
    bajarHasta a
      | cabe (tablero j) (desplazar 1 0 a) = bajarHasta (desplazar 1 0 a)
      | otherwise                          = a

celdaTexto :: Juego -> Celda -> String
celdaTexto j pos
  | pos `elem` celdas (activa j) = bloque (pieza (activa j))
  | pos `elem` celdas (sombra j) = "\ESC[90m::\ESC[0m"
  | otherwise = case tablero j !! fst pos !! snd pos of
      Just p  -> bloque p
      Nothing -> "\ESC[90m .\ESC[0m"

lineasTablero :: Juego -> [String]
lineasTablero j =
  [borde] ++ [ "|" ++ concat [celdaTexto j (r, c) | c <- [0 .. columnas - 1]] ++ "|"
             | r <- [0 .. filas - 1] ] ++ [borde]
  where
    borde = "+" ++ replicate (2 * columnas) '-' ++ "+"

vistaSiguiente :: Pieza -> [String]
vistaSiguiente p =
  [ concat [ if (r, c) `elem` forma p then bloque p else "  " | c <- [-1 .. 2] ]
  | r <- [0, 1] ]

panel :: Juego -> [String]
panel j =
  [ ""
  , "   TETRIS EN HASKELL"
  , ""
  , "   Puntos: " ++ show (puntos j)
  , "   Lineas: " ++ show (lineas j)
  , "   Nivel:  " ++ show (nivel j)
  , ""
  , "   Siguiente:" ]
  ++ map ("   " ++) (vistaSiguiente (siguiente j)) ++
  [ ""
  , "   a / d : mover"
  , "   w     : girar"
  , "   s     : bajar"
  , "   ESPACIO: caida rapida"
  , "   q     : salir"
  , ""
  , if terminado j then "   *** FIN DEL JUEGO ***" else "" ]

dibujar :: Juego -> IO ()
dibujar j = do
  let cuadro = zipWith (\a b -> a ++ b ++ "\ESC[K")
                       (lineasTablero j) (panel j ++ repeat "")
  putStr ("\ESC[H" ++ unlines cuadro ++ "\ESC[J")
  hFlush stdout

-- ------------------------------------------------------------
-- Ciclo principal
-- ------------------------------------------------------------

-- Hilo que solo lee el teclado y manda cada tecla a un canal.
-- Asi el juego puede esperar una tecla "con tiempo limite" sin usar hWaitForInput.
-- En la consola de Windows getChar espera a que se pulse Enter, asi que se
-- lee el teclado directamente con _kbhit / _getch (libreria C de Windows).
foreign import ccall unsafe "conio.h _kbhit" c_kbhit :: IO CInt
foreign import ccall unsafe "conio.h _getch" c_getch :: IO CInt

lector :: Chan Char -> IO ()
lector canal = do
  hay <- c_kbhit
  if hay == 0
    then threadDelay 10000 >> lector canal
    else do
      k <- c_getch
      if k == 0 || k == 224
        then do                           -- tecla especial (flechas): llega un segundo codigo
          k2 <- c_getch
          case k2 of
            75 -> writeChan canal 'a'     -- izquierda
            77 -> writeChan canal 'd'     -- derecha
            72 -> writeChan canal 'w'     -- arriba
            80 -> writeChan canal 's'     -- abajo
            _  -> return ()
        else writeChan canal (chr (fromIntegral k))
      lector canal

-- 'proxima' es el momento (en segundos) de la siguiente caida automatica
jugar :: Bool -> Chan Char -> Juego -> Double -> IO ()
jugar turnos teclas j proxima = do
  dibujar j
  if terminado j
    then putStrLn ""
    else do
      ahora <- getMonotonicTime
      let microseg = ceiling (max 0 (proxima - ahora) * 1000000) :: Int
      -- en modo por turnos se espera la tecla sin limite de tiempo
      resultado <- if turnos
                     then Just <$> readChan teclas
                     else timeout microseg (readChan teclas)
      case fmap toLower resultado of
        Just 'q'   -> return ()
        Just tecla -> do
          let j1 = aplicar tecla j
              -- en modo por turnos, cada tecla tambien hace caer una fila
              j2 = if turnos && tecla /= ' ' && tecla /= 's' then bajar j1 else j1
          jugar turnos teclas j2 proxima
        Nothing -> do
          t <- getMonotonicTime
          let j' = bajar j
          jugar turnos teclas j' (t + retardo j')

main :: IO ()
main = do
  args <- getArgs
  nsec <- getMonotonicTimeNSec
  let (p1, s1) = aleatoria (fromIntegral (nsec `mod` 2147483647))
      (p2, s2) = aleatoria s1
      inicial  = Juego tableroVacio (nueva p1) p2 s2 0 0 False
  hSetBuffering stdin NoBuffering
  hSetBuffering stdout (BlockBuffering Nothing)
  hSetEcho stdin False
  teclas <- newChan
  _ <- forkIO (lector teclas)
  putStr "\ESC[2J\ESC[?25l"          -- limpia la pantalla y oculta el cursor
  t <- getMonotonicTime
  jugar ("turnos" `elem` args) teclas inicial (t + retardo inicial)
    `finally` (putStr "\ESC[0m\ESC[?25h" >> hSetEcho stdin True >> hFlush stdout)