
%potential bug - make sure 'data' has enough rows.

% here, we assume 3 factors for the compedence of a stock: it's potential
% to surprise, it's profitablilty over time, and if its relatively
% expensive. we adress it using derivatives, integrals and a moving
% average, to all of which we assign a personalized weight - value for
% time, money and timing accordingly.

%using data from chatgpt, i arrived at an expected
% weight distribution in the general public, 
% and according to 2 different proxies:
% 1. provident fund's investment plan distribution (moderate risk,safe, risky)
% 2. job distribution in population (scholars+labor, businessmen,
% politicians+strategists)

%those provided distributions as follows:
%1. 0.3-0.4; 0.5-0.6; 0.1-0.2
%2. 0.2-0.3; 0.6-0.7; 0.05-0.1

% considering the weighting is not very sensitive, we could roughly agree
% on 0.3; 0.6; 0.1

%note: should i use data regarding open prices or close?
%i believe that close prices are more relevant for traders, and open are
%better for investors. also, using open helps ignoring rises that collapsed
% the following day.
% nontheless, people usually use graphs of close in their estimations. for
% now, i will use open.

%% creating table
source = '24to25/100sp.csv';
%source = 'MBLY.csv'; %(grade can be found at 'grades' in first square)
data = rmmissing(readtable(source),2); %create table wo nans



%% constants

%how much do you value time (1) vs money (2) vs opprtunity (3)?
% how much should large std be penalized in volatility (4) and growth (5)?

%weight = [0.4 ; 0.35 ; 0.25]; %my preference
weight = [0.3 ; 0.5 ; 0.2 ; 0.26 ; 0.51]; %estimation within the general public (works pretty good on past 10 years)
%weight = [0.4 ; 0.5 ; 0.1 ; -0.05 ; 0.48]; %personal tweaking
% weight = [0.9 ; 0 ; 0.1 ; -0.1 ; 0]; %wierd best results after tweaking


%% empty vectors
numOfStocks = floor(size(data,2)/2);
std_d = zeros(numOfStocks,1);
avg_d = zeros(numOfStocks,1);
std_i = zeros(numOfStocks,1);
avg_i = zeros(numOfStocks,1);
moving_avg_diff = zeros(numOfStocks,1);

goodStocks = zeros(numOfStocks,1);


%% analysis

for stock = 1:numOfStocks %for each stock

    %extract prices and dates of the stock
    dates = table2array(data(:,2*stock - 1));
    prices = table2array(data(:,2*stock));
    
    %then find the std and mean of the stock's normalized derivative
    derivative = diff(prices) ./ prices(1:end-1);
    std_d(stock) = std(derivative);
    avg_d(stock) = mean(derivative);

    % and of it's integral (could use more thoughts on better forms of
    % integration here)
    
    %% version 1
%     %this interpretation asks how profitable was it to *buy* the stock during
%     %the measured year
%     integral = zeros(length(prices)-1 ,1);
%     for i = 1:length(prices)-1
%         integral(i) = (prices(end)-prices(i))./prices(i);
%     end
%     std_i(stock) = std(integral);
%     avg_i(stock) = mean(integral);

    %% version 2
    % this interpretation asks how profitable was it to *sell* the stock
    % during the measured year.
    integral = zeros(length(prices)-1 ,1);
    for i = 1:length(prices)-1
        %integral(i) = sum(prices(1:i))./prices(1) - 1; %wierdly works
        integral(i) = sum(prices(1:i)./(prices(1)*i) - 1); %normalized, but the integral rises each interval: what does averaging even mean?
    end
    std_i(stock) = std(integral);
    avg_i(stock) = mean(integral);    

    %%
    %now for the distance from the moving average, assuming that the closer
    %we are to the average, the better

    tau = 0.05*mean(prices); %(tau is the typical deviation from average considered significant)
    moving_avg_diff(stock) = exp(-abs(mean(prices)-prices(end))/tau);

    % now, we need to decide if the stock is good
    if avg_d(stock) > 0.1 && avg_i(stock) > 0.1
        goodStocks(stock*2-1) = 1;
    end

end

%sometimes the stocks we want dont exist. in this case, we find the leading
%stocks in our database.

% to do so, we first need to normalize our grading systems, to
% have mean 0 and std 1. we will also want to penalize stocks with low
% consistency (high std_d and std_i).
%(notice: i have significantly reduced the penalty to grades with big
% std's,to give more importance to performance vs consistency)

%% first approach - first standardize then penalize
% this approach allows for penalties and grades to be consistent vs other stocks
mu_avg_d = mean(avg_d); sigma_avg_d = std(avg_d);
mu_std_d = mean(std_d); sigma_std_d = std(std_d);
mu_avg_i = mean(avg_i); sigma_avg_i = std(avg_i);
mu_std_i = mean(std_i); sigma_std_i = std(std_i);
mu_ma = mean(moving_avg_diff); sigma_ma = std(moving_avg_diff);

Z_avg_d  = (avg_d - mu_avg_d)./sigma_avg_d;
Z_std_d = (std_d - mu_std_d)./sigma_std_d;
Z_avg_i  = (avg_i - mu_avg_i)./sigma_avg_i;
Z_std_i = (std_i - mu_std_i)./sigma_std_i;
Z_ma = (moving_avg_diff - mu_ma)./sigma_ma;

% and now we can create a weighted grading system.

grades = [Z_avg_d./(1+weight(4)*Z_std_d), Z_avg_i./(1+weight(5)*Z_std_i), Z_ma]*weight(1:3);
% (0.26, 0.51 is based on trial and error. works pretty good on past 10
% years, together with weights [0.3 ; 0.5 ; 0.2])

%% second approach: first penalize then standardize
% this approach allows for penalties and grades to be consistent vs other parameters
%(i believe this approach is less fair, because a stock gets penalty for
%natural variabillity, and so volatile parameters will get lower weight

%d = avg_d./(1+0.05*std_d); i = avg_i./(1+0.05*std_i);
%grades = [(d-mean(d))./std(d), (i-mean(i))./i, Z_ma]*weight;

%% third approach - without penalties
%grades = [Z_avg_d, Z_avg_i, Z_ma]*weight;

%%
[leaders_grade,leadingStocks] = maxk(grades,3);

%and finally display the results
column_headers = data.Properties.VariableNames;
disp('good stocks:')
disp(column_headers(goodStocks ~=0))
disp('leading stocks (grade, stock):')
for n = 1:3
    disp([leaders_grade(n), column_headers(leadingStocks(n)*2-1)]);
end
disp('see full grading list in results vector')

%% translate results to stock names
%stocks_names = table2array(readtable('1000stock_names.csv'));
stocks_names = table2array(readtable('100sp_stock_names.csv'));


header_to_PKey = cellfun(@(x) str2double(regexp(x, '\d+', 'match')), column_headers(1:2:(size(grades,1)*2-1)));
%this function is fragile. 
%it relies on the stocknames vector starting from location 2 because in the
%original table the first name is in A2. also the titles cannot have any
%numbers besides primary key.
%it is worth comparing it to 'leading stocks' every once in a while.

result = sortrows([num2cell(grades) stocks_names(header_to_PKey)],'descend');

%% check perfoemance
%in this section we can see the profitablilty of the suggested stocks for
%old enough data ( from at least one year ago).

%% %% check profit using DCA
% 
% %conclusion: DCA is not the right way to go here. it assumes that over time
% %the stock will rise, so that by the next year we will surely get profit.
% %this might only be true in longer periods. further investigation is
% %required
% 
% numStocksInPortfolio = 10;
% periodic_invest = 200; %(in each stock)
% investingPeriod = 30; %(each __ days)
% 
% % first, we need to identify leading stocks and find their primary key
% [~,chosen_stocks] = maxk(grades,numStocksInPortfolio);
% chosen_stocks = header_to_PKey(chosen_stocks);
% 
% %then, we find their performance during the next year
% %% for 1k stocks
% % next_year = @(n) ['2' num2str(str2double(n) + 1) 'to2' num2str(str2double(n) + 2) '/biggest_1k.csv'];
% % performance = regexprep(source, '2(\d)to2(\d)/biggest_1k.csv', '${next_year($1)}');
% % performance = readtable(performance);
% % performance = rmmissing(performance(:,(chosen_stocks-1).*2));
% 
%% %% for 100 sp stocks
% next_year = @(n) ['2' num2str(str2double(n) + 1) 'to2' num2str(str2double(n) + 2) '/100sp.csv'];
% performance = regexprep(source, '2(\d)to2(\d)/100sp.csv', '${next_year($1)}');
% performance = readtable(performance);
% performance = rmmissing(performance(:,(chosen_stocks-1).*2),2);
% 
% 
% %(note - this requires tables from all years to look the same even if data
% %is missing in some columns, and for stock numbers in table to be consistent
% % with the column numbers)
% 
% %now we need to see our portfolio growth if we DCA based on highest graded
% %stocks
% %to do so, we first will calculate how much assets we get to buy each period
% 
% period = 1:investingPeriod:size(performance,1);
% holdings = zeros(1,size(performance,2));
% for p = period
%     holdings = holdings + periodic_invest./table2array(performance(p,:));
% end
% initial_cash = periodic_invest*numStocksInPortfolio*numel(period);
% final_cash = sum(holdings.*table2array(performance(end,:)));
% 
% disp('DCA:')
% % disp('initial cash ($) = ')
% % disp(initial_cash)
% % disp('final cash ($) = ')
% % disp(final_cash)
% disp('profit in % :')
% disp(100*(final_cash-initial_cash)/initial_cash)
% 
%% %% check profit using yearly price change
% 
% % here, we will simply check how much our portfolio raised in the investing
% % year. we consider 'periodic_invest' to be the initial investment in each
% % stock
% 
% initial_cash = periodic_invest*numStocksInPortfolio;
% holdings = periodic_invest./table2array(performance(1,:));
% final_cash = sum(holdings.*table2array(performance(end,:)));
% 
% disp('yearly price change:')
% disp('profit in %:')
% disp(100*(final_cash-initial_cash)/initial_cash)
