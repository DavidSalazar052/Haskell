factorial :: Integer -> Integer
factorial 0 = 1
factorial n = n * factorial (n - 1)

main :: IO ()
main = do
    putStrLn("Factorial de 5: " ++ show (factorial 5))
    putStrLn("Factorial de 10: " ++ show (factorial 10))
    putStrLn("Factorial de 0: " ++ show (factorial 0))