# SPIRIT Token Distribution System

This system is built on Solidity smart contracts and leverages Uniswap liquidity pools to create a decentralized token distribution mechanism. The core architecture centers around a **Swapper Router** contract that manages SPIRIT token acquisition and distribution. The router can swap for SPIRIT tokens and distribute them to child token stakers (like Abraham), while also interacting with a central SPIRIT/ETH liquidity pool. An NFT auction module accepts USDC input and contributes additional SPIRIT rewards to the staking pools, creating multiple revenue streams for token holders.

The system utilizes interconnected Uniswap liquidity pools to facilitate token swaps and provide liquidity for the SPIRIT ecosystem. The central SPIRIT/ETH pool serves as the primary trading pair, with bidirectional connections to specialized pools for each child token (ABRAHAM/SPIRIT, SOLINNE/SPIRIT, CITIZEN_BOT/SPIRIT, etc.). Each child token comes with its own complete set of components: a token contract, liquidity pool, and staking pool. Child token stakers receive streamed rewards from both the Swapper Router and NFT auction proceeds, creating a sustainable token distribution model that incentivizes long-term participation through continuous reward streaming.


# Pieces 
- SPIRIT superToken (1B)
    12 month cliff + 24 months for team (25%)                           x   
    6 months eden operations (25%)                                      x   
    liquidity pool (25%) 
        liquidity pool (locked 20% in reasonable ranges)                N
        liquidity pool (unlocked 5% in unreasonable range)              x
    /?? community (unlocked 25%)                                        N
- SPIRIT/ETH liquidity pool                                             x - uniV4


- Maybe (xSpirit)
    Users get merkle drop of xSpirit                                     
    Users can "swap+stake" into any child token                         
    Staked assets go with a minimum 3month lock                         


- For each $CHILD       - (1B supply)      - admin only factory                      
    - SuperToken                                                        x
    - CHILD/SPIRIT Liquidity Pool                                       N - uniV4
    - Liquidity Locker - locks uniswap pool position                    N - uniV4
    - Other distributions                                               
        47.50% to liquidity                                             x
        2.50% to airdrop (early works holders)
        12 mo locked stake - 25% to agent                               N
        12 mo locked stake - 25% to artist                              N
    - CHILD Flowrate controller contract                                N
        smooths flowrate to 1 week                                      
    - Staking contract                                                  N
        users stake CHILD                                               
        users get SPIRIT stream                                         
        CHILD has a withdrawal cooldown of a week     
        using a distribution pool                                       
        Different staking durations come with multiplier on units       N
            What are the multipliers (n*0.25/week)
            Restaking behavior (smooth function)
            Maximum 1 year boost

- auxiliary
    - swapSPIRIT+stake + connectPool
    - swapXSPIRIT+stake + connectPool
    - swapETH+stake + connectPool


October 5th - ""LFG""