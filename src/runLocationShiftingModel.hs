module Main where 
import LocationShiftingModel 
import Numeric
import Data.List (intercalate, transpose)

n_nodes_HPC = 100 -- 100 rough figure for HPC2N from https://www.hpc2n.umu.se/resources/hardware/kebnekaise

-- The "Next Generation Data Centre" in Cardiff has 19,000 nodes

{-
To incorporate data centre infrastructure embodied carbon from the Schneider Electric whitepaper:
- take the overall figure over 20 years, i.e. 2400 tCO2e for a 1 MW data centre over 20 years
- per year that is 120 tCO2e for a 1 MW data centre per year
- per year that is 120,000 kgCO2e for a 1,000 kW data centre per year

- for 4.55 kW (the AI server) that is 120*4.55 per node
- for  1.2 kW  (the AI server) that is 120*1.2 per node
 
-}

c_emb_infra_HPC :: KgCO2ePerYear
c_emb_infra_HPC = 120*p_node_HPC -- 
c_emb_2xEPYC = 1200 -- kgCO2e per node
dt_HPC = 4

p_node_HPC :: KW
p_node_HPC = 1.2
pue_ASCG = 1.62 
pue_HPC2N = 1.03

-- we move 50% of the 100% load; no overhead, so almost as good as it gets
lsm_HPC_1 = LSMData 
    n_nodes_HPC 
    1
    1
    ((c_emb_2xEPYC/dt_HPC) + c_emb_infra_HPC) -- c_em 2xEPYC: 1200 for 0.5 TB, 1599 for 5TB 2042 for 10 TB (from calculateServerEmbodiedCarbon-WLCG.hs), divided by 4 years; let's take the former to be conservative    
    (p_node_HPC*pue_ASCG*24*365*(ci_TW/1000)) --  c_hi ASCG
    (p_node_HPC*pue_HPC2N*24*365*(ci_SE/1000)) -- c_lo HPC2N
    1.0  -- lambda_hi -- ASCG fully loaded
    0.5 -- lambda_lo -- HPC2N 50% has free capacity
    0.3 -- gamma , idle power consumption
    1.0 -- alpha , fraction of actual workload that can be moved
    1.0 -- beta , fraction of the time work can be moved
    0.0 -- eta, overhead factor for emissions incurred because of geographic load shifting
-- we move 12.5% of the 100% load; overhead 5%
lsm_HPC_2 = lsm_HPC_1{lambda_lo=0.8, lambda_hi=0.8,eta=0.01}
-- we move 12.5% of the 80% load; overhead 5%
lsm_HPC_3 = lsm_HPC_2{alpha=0.25, beta=0.5}
-- we move 6.25% of 100% between US and UK, overhead 1%
lsm_HPC_4 = lsm_HPC_2{
    c_hi=3878.9,c_lo=1303.5 -- I think this is US / UK so BNL
    -- ,alpha=0.25, beta=0.25, eta=0.01
    }
lsm_HPC_5 = lsm_HPC_3{
    c_hi=3878.9,c_lo=1303.5 -- I think this is US / UK so BNL
    -- ,alpha=0.25, beta=0.25, eta=0.01
    }

p_node_com = 4.550 -- kW -- for DGX-A100; for 2xEPYC it is 1.2 
c_emb_infra_com = 120*p_node_com*pue_com -- kgCO2e/y per node
pue_com = 1.16

c_emb_com = 5730 -- embodied carbon of the DGX-A100, in  kgCO2, from calculateServerEmbodiedCarbon-DGX-A100.hs

dt_com = 4 -- years
ci_SE = 36
ci_TW = 636

ci_US = 369 --384 -- gCO2e/kWh
ci_UK = 211
ci_DE = 344
ci_FR = 44 
ci_ES = 146

ci_solar = 41
ci_wind = 11

sun_hours_max=2920
sun_hours_US=2627
sun_hours_UK=1524
sun_hours_D=1665
sun_hours_F=sun_hours_max
sun_hours_avg = (sun_hours_US+sun_hours_UK+sun_hours_D+3*sun_hours_F)/6


ci_avg_for_solar = (ci_US+ci_UK+ci_DE)/3
ci_lo_solar = ci_solar
ci_hi_solar =  (ci_avg_for_solar*24-ci_solar*8)/16
solar_beta_corr = sun_hours_avg/sun_hours_max -- 0.83 -- correction for actual hours of sunshine
ci_hi_solar_corr =  (ci_avg_for_solar*24-ci_solar*8*solar_beta_corr)/(24-8*solar_beta_corr)

ci_avg_for_wind = (ci_US+ci_UK+ci_DE+ci_ES)/4
ci_lo_wind = ci_wind
ci_hi_wind =  2*ci_avg_for_wind - ci_lo_wind  -- ci_avg_for_wind = (ci_hi_wind*12 + ci_lo_wind*12)/24 => ci_hi_wind = (24*ci_avg_for_wind - c_lo_wind*12)/12
-- WAS (ci_avg_for_wind-ci_lo_wind)/2
wind_beta_corr = 0.6 -- correction for actual wind load, 30% instead of 50%
-- ci_avg_for_wind = (ci_hi_wind*(1-0.5*beta)+c_lo_wind*0.5*beta)
ci_hi_wind_corr = (ci_avg_for_wind-ci_lo_wind*0.5*wind_beta_corr)/(1-0.5*wind_beta_corr)


n_nodes_300MW = 300000/(p_node_com*pue_com)

lsm_com_1 = LSMData 
    n_nodes_300MW 
    2
    2
    ((c_emb_com/dt_com) + c_emb_infra_com) -- c_em
     
    (p_node_com*(ci_US/1000)*pue_com*24*365) -- 17060.8 -- 4550 W, 369 gCO2e/ci_US(US), PUE pue
    (p_node_com*(ci_UK/1000)*pue_com*24*365) -- 4550 W, 124 gCO2e/kWh (UK), PUE 
    0.5 -- lambda_lo
    0.5 -- lambda_hi
    0.3 -- gamma; could be as high as 0.5 
    1.0 -- alpha all work can be moved
    1.0 -- beta all of the time 
    0.0 -- eta    

-- lsm_com_0=lsm_com_1{gamma=0.0,c_em=0.0}
-- lsm_com_2=lsm_com_1{lambda_hi=0.8,lambda_lo=0.8,alpha=0.5,beta=0.5,eta=0.0}
-- lsm_com_3=lsm_com_1{alpha=0.5,beta=0.5,eta=0.0}
-- lsm_com_4=lsm_com_3{alpha=0.25,beta=0.25}

-- This is for the new examples, wind and solar, 4 locations


-- Solar across three sites + 1 nuclear
lsm_com_solar=lsm_com_1{
    c_hi=ci_hi_solar_corr*p_node_com*pue_com*24*365/1000,
    c_lo=ci_lo_solar*p_node_com*pue_com*24*365/1000,
    lambda_hi=1/1.2, -- this is a very high load, I took it from Lindberg et al.
    lambda_lo=1/1.2,
    alpha=0.2, -- this means we can move 20% of the load. If the target has (1-1/1.2) free then we can move 0.2/1.2 
    beta=solar_beta_corr*5/8 -- *2/3 -- the 70% is to correct for fewer actual hours of sunshine; the 5/8 is correlation between US, UK and Germany
}
-- WV: I think the first factor in beta might be 0.83 i.o. 0.7. Average sunshine factor is 0.66 but France is always on so (0.66+1)/2
-- It changes the reduction from 4.2% to 5%
-- If we correct for the beta in ci_hi_solar_corr, then with 0.7 we get 4.0%; with 0.83 we get 4.8%


-- Wind between four sites, 2x2
lsm_com_wind=lsm_com_solar{
    c_hi=ci_hi_wind_corr*p_node_com*pue_com*24*365/1000,
    c_lo=ci_lo_wind*p_node_com*pue_com*24*365/1000,
    beta=wind_beta_corr*0.9
    }
-- Some ideal scenario, is this used?
lsm_com_7=lsm_com_wind{c_lo=0,c_em=0,gamma=0,beta=1}


header = [
    "$n_n$",
    "$n_{hi}$",
    "$n_{lo}$",
    "Embodied $c_{em}\\, (kgCO_2e/y)$",
    "Operational, high CI $c_{hi}\\, (kgCO_2e/y)$",
    "$c_{lo}\\, (kgCO_2e/y)$",
    "$\\lambda_{hi}$",
    "$\\lambda_{lo}$",
    "$\\gamma$",
    "$\\alpha$",
    "$\\beta$",
    "$\\eta$", 
    "\\emph{overhead} ($tCO_2e/y$)", 
    "embodied ($tCO_2e/y$)",
    "baseline ($tCO_2e/y$)", 
    "location shifting ($tCO_2e/y$)", 
    "reduction (\\%)"
    ]


res_table_commercial = let
        -- header = ["$n_n$","$n_{hi}$","$n_{lo}$","$c_{em}$","$c_{hi}$","$c_{lo}$","$\\lambda_{hi}$","$\\lambda_{lo}$","$\\gamma$","$\\alpha$","$\\beta$","$\\eta$", "\\emph{overhead}", "baseline", "location shifting", "reduction"]
        rows = map (\lsm_commercial -> 
                let
                    c_b_commercial = emissionsBaseline lsm_commercial
                    c_ls_commercial = emissionsWithLocationShifting lsm_commercial
                    c_oh_commercial = emissionsOverhead lsm_commercial
                    c_emb_commercial = emissionsEmbodied lsm_commercial
                    red_commercial = 100*(c_b_commercial - c_ls_commercial)/c_b_commercial
                in 
                    (showListLSM lsm_commercial)++[
                        (showFFloat (Just 0) (fromRational $ c_oh_commercial/1000) ""),
                        (showFFloat (Just 0) (fromRational $ c_emb_commercial/1000) ""),
                        (showFFloat (Just 0) (fromRational $ c_b_commercial/1000) ""),
                        (showFFloat (Just 0) (fromRational $ c_ls_commercial/1000) ""),
                        (showFFloat (Just 1) (fromRational red_commercial) "\\%") 
                    ]
            ) [lsm_com_solar,lsm_com_wind]
    in
        transpose (header:rows)

n_steps = 20
effect_of_load lsm_commercial =
    let
        alpha_opt lambda  
                | lambda/n_steps >= 0.5 = 1 -- 1/l-1 > 1 -> 1/l > 2 -> l > 1/2
                | otherwise = 1 -- 1/(lambda/n_steps)-1 
        lsms = [
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=lambda/n_steps,alpha=alpha_opt lambda },
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=lambda/n_steps,gamma=0,alpha=alpha_opt lambda},
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=lambda/n_steps,gamma=0,c_em=0,alpha=alpha_opt lambda},
                \lambda -> lsm_commercial{lambda_hi=lambda/n_steps,lambda_lo=lambda/n_steps,gamma=0,c_em=0,beta=1,alpha=alpha_opt lambda} -- ,
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
            [loadValStrs] ++ loadResListStrs -- ++ (foldl (++) [] $ foldl (++) [] $ nested_rows)

createCSV table = map (\row -> intercalate ", " row) $ transpose table 

main = do
    mapM putStrLn $ createCSV $ createTableLoad $ (effect_of_load lsm_com_solar)++(effect_of_load lsm_com_wind) 

      

res_table_HPC = let
        -- header = ["n_n", "n_{hi}", "n_{lo}", "c_{em}", "c_{hi}", "c_{lo}", "$\\lambda_{hi}", "\\lambda_{lo}", "\\gamma", "\\alpha", "\\beta", "\\eta", "overhead", "baseline", "location shifting", "reduction"]
        
        rows = map (\lsm_HPC ->
                let
                    c_b_HPC = emissionsBaseline lsm_HPC
                    c_ls_HPC = emissionsWithLocationShifting lsm_HPC
                    c_oh_HPC = emissionsOverhead lsm_HPC
                    c_emb_HPC = emissionsEmbodied lsm_HPC
                    red_HPC = 100*(c_b_HPC - c_ls_HPC)/c_b_HPC            
                in
                    (showListLSM lsm_HPC)++[
                        (showFFloat (Just 0)  (fromRational $ c_oh_HPC/1000) ""),
                        (showFFloat (Just 0)  (fromRational $ c_emb_HPC/1000) ""),
                        (showFFloat (Just 0)  (fromRational $ c_b_HPC/1000) ""),
                        (showFFloat (Just 0) (fromRational $ c_ls_HPC/1000) ""),
                        (showFFloat (Just 1) (fromRational red_HPC) "\\%")
                    ]
                
            ) [lsm_HPC_1,lsm_HPC_2,lsm_HPC_3,lsm_HPC_4,lsm_HPC_5]
    in
        transpose (header:rows)

-- main = do
--     putStrLn "\\textbf{HPC Centre Parameters} & \\textbf{Scenario 1} & \\textbf{Scenario 2} & \\textbf{Scenario 3} & \\textbf{Scenario 4} & \\textbf{Scenario 5}\\tabularnewline\n\\hline"
--     mapM (\row -> putStrLn $ "\\hline\n" ++(intercalate " & "  row)++"\\tabularnewline") res_table_HPC
--     putStrLn "\\hline\n"
--     putStrLn "\\textbf{AI Data Centre Parameters} & \\textbf{Scenario 1 (Solar)} & \\textbf{Scenario 2 (Wind)}\\tabularnewline\n\\hline"
--     mapM (\row -> putStrLn $ "\\hline\n" ++(intercalate " & "  row)++"\\tabularnewline") res_table_commercial
--     putStrLn "\\hline\n"
-- main = do        
--     putStrLn ( intercalate ", " $ map (\x-> (show . fromRational) $ x/n_steps) [1 .. n_steps-1])
--     print $ createTableLoad $ effect_of_load lsm_com_solar
    -- mapM putStr $ map (\ls1 -> -- ls1 is a list of lists 
    --         unlines $
    --             map (\ls2 -> -- ls2 is a list
    --                 intercalate ", " $ map show ls2
    --             ) ls1
    --     ) [effect_of_load lsm_com_solar]
    -- putStrLn "\n"
    -- putStrLn ( intercalate ", " $ map (\x-> (show . fromRational) $ x/n_steps) [1 .. n_steps-1])
    -- mapM putStr $ map (\ls1 -> -- ls1 is a list of lists 
    --         unlines $
    --             map (\ls2 -> -- ls2 is a list
    --                 intercalate ", " $ map show ls2
    --             ) ls1
    --     ) [effect_of_load lsm_com_wind]
