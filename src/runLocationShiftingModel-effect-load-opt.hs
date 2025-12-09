module Main where 
import LocationShiftingModelCommon (doeCommercial,doeHPC)     
import LocationShiftingModel 
import Numeric
import Data.List (intercalate, transpose)


n_steps = 100
effect_of_load lsm_commercial =
    let
        alpha_opt lambda  
                | lambda/n_steps >= 0.5 = 1 -- 1/l-1 > 1 -> 1/l > 2 -> l > 1/2
                | otherwise = 1 -- 1/(lambda/n_steps)-1 
        lsms = [
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=0.5,alpha=alpha_opt lambda },
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=0.5,gamma=0,alpha=alpha_opt lambda},
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=0.5,c_em=0,alpha=alpha_opt lambda},
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=0.5,gamma=0,c_em=0,alpha=alpha_opt lambda},
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=0.5,gamma=0,c_em=0,beta=1,alpha=alpha_opt lambda} -- ,
                -- \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=lambda/n_steps,gamma=0,c_em=0,beta=1,alpha=1}
            ]
    in 
        map (
            \lsm -> (
                map (
                    \lambda ->  (
                                let 
                                    c_gls_commercial = emissionsWithLocationShifting $ lsm lambda
                                    c_b_commercial = emissionsBaseline $ lsm lambda
                                    red_commercial = 100*(c_b_commercial - c_gls_commercial)/c_b_commercial
                                in
                                    fromRational red_commercial
                                    -- fromRational (c_gls_commercial/1000000) -- red_commercial
                            )
                ) [1 .. n_steps]
            )
        ) lsms

createTableLoad loadResList = let
        -- header=["Load","Actual","No idle power", "No embodied", "Full flexibility"]
        loadValStrs = map (\x-> (show . fromRational) $ x/n_steps) [1 .. n_steps]
        loadResListStrs = map (\row -> map show row) loadResList
        in
            [loadValStrs] ++ loadResListStrs

createCSV table = map (\row -> intercalate ", " row) $ transpose table 

main = do
    mapM putStrLn $ createCSV $ createTableLoad $ foldl (++) [] $ map  effect_of_load $ doeHPC

      
