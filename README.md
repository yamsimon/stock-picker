# stock-picker
NOTE: This code is for research and educational purposes only. This is not financial advice.

The following code takes data from google sheets 'GOOGLEFINANCE' 
(link: https://docs.google.com/spreadsheets/d/1ykQ412VehQPBjSppehq14MH0bEFMgxVaqg_wSYQyY6k/edit?usp=sharing)
command for the prior year and seeks good investing opportunities according to the following system:


we assume 3 factors for the compedence of a stock: it's potential
to surprise, it's profitablilty over time, and if its relatively
expensive. we adress it using derivatives, integrals and a moving
average, to all of which we assign a personalized weight - value for
time, money and timing accordingly.

using data from chatgpt, i arrived at an expected
weight distribution in the general public, 
and according to 2 different proxies:
 1. provident fund's investment plan distribution (moderate risk,safe, risky)
2. job distribution in population (scholars+labor, businessmen,
politicians+strategists)

those provided distributions as follows:
1. 0.3-0.4; 0.5-0.6; 0.1-0.2
2. 0.2-0.3; 0.6-0.7; 0.05-0.1

considering the weighting is not very sensitive, we could roughly agree
on 0.3; 0.6; 0.1
