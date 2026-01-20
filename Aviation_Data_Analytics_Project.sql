/*
===============================================================================
        AIRLINE DATA ANALYTICS (SQL PROJECT)
===============================================================================
Author: [Your Name]
Topic: Revenue, Operations, Passenger, Crew, and Agent Performance Analysis
*/

-------------------------------------------------------------------------------
-- I. REVENUE ANALYTICS
-------------------------------------------------------------------------------

-- 1. Airline Revenue Ranking
SELECT 
    a.Airline_Code,
    FORMAT(SUM(fa.price), 'C', 'hy-AM') AS Total_Revenue
FROM [Flights_Schema].[Airlines] a
JOIN [Flights_Schema].[Flights] f ON f.Airline_Code = a.Airline_Code
JOIN [Flights_Schema].[Tickets] t ON t.Flight_ID = f.Flight_ID
JOIN [Flights_Schema].[Fares] fa ON fa.Flight_ID = t.Flight_ID -- Note: Adjusted join based on your query logic
GROUP BY a.Airline_Code
ORDER BY SUM(fa.price) DESC;

-- 2. Route Revenue Leader (Top performing city-to-city route)
WITH Max_Gain AS (
    SELECT TOP 1 
        f.Departure_Airport_Code,
        f.Arrival_Airport_Code,
        SUM(price) AS sum_revenue
    FROM [Flights_Schema].[Flights] f
    JOIN [Flights_Schema].[Tickets] t ON t.Flight_ID = f.Flight_ID
    JOIN [Flights_Schema].[Fares] fa ON fa.Fare_ID = t.Fare_ID
    GROUP BY f.Departure_Airport_Code, f.Arrival_Airport_Code
    ORDER BY sum_revenue DESC
)
SELECT 
    a1.City AS Departure_City,
    a2.City AS Arrival_City, 
    FORMAT(m.sum_revenue, 'C', 'hy-AM') AS max_revenue 
FROM Max_Gain m
JOIN [Flights_Schema].[Airports] a1 ON a1.[Airport_Code] = m.Departure_Airport_Code
JOIN [Flights_Schema].[Airports] a2 ON a2.[Airport_Code] = m.Arrival_Airport_Code;

-- 3. Revenue by Booking Class (Economy/Business/First)
SELECT 
    f.Booking_Class,
    FORMAT(SUM(price), 'C', 'hy-AM') AS Total 
FROM [Flights_Schema].[Fares] f
JOIN [Flights_Schema].[Tickets] t ON t.Fare_ID = f.Fare_ID
GROUP BY f.Booking_Class
ORDER BY SUM(price) DESC;

-- 4. Most Sold Booking Class
SELECT TOP 1 
    COUNT(*) AS Total_Sold,
    f.Booking_Class 
FROM [Flights_Schema].[Tickets] t
JOIN [Flights_Schema].[Fares] f ON f.Fare_ID = t.Fare_ID
GROUP BY f.Booking_Class
ORDER BY Total_Sold DESC;

-- 5. Average Ticket Revenue per Airline
SELECT 
    a.Name,
    FORMAT(AVG(fa.Price), 'C', 'hy-AM') AS avg_airline 
FROM [Flights_Schema].[Airlines] a
JOIN [Flights_Schema].[Flights] f ON f.Airline_Code = a.Airline_Code
JOIN [Flights_Schema].[Tickets] t ON t.Flight_ID = f.Flight_ID
JOIN [Flights_Schema].[Fares] fa ON fa.Fare_ID = t.Fare_ID
GROUP BY a.Name;

-- 6. Flight-Level Revenue
SELECT 
    f.Flight_Number, 
    SUM(price) AS Total_price 
FROM [Flights_Schema].[Flights] f
LEFT JOIN [Flights_Schema].[Tickets] t ON t.Flight_ID = f.Flight_ID
LEFT JOIN [Flights_Schema].[Fares] fa ON fa.Fare_ID = t.Fare_ID
GROUP BY f.Flight_Number
ORDER BY Total_price DESC;

-- 7. Monthly Revenue Trend (2025 Seasonality)
SELECT  
    MONTH([Booking_Date]) AS [Month],
    SUM(price) * 100 / (
        SELECT SUM(price) 
        FROM [Flights_Schema].[Tickets] t2
        JOIN [Flights_Schema].[Fares] f2 ON f2.Fare_ID = t2.Fare_ID
        WHERE YEAR([Booking_Date]) = 2025
    ) AS Percentage
FROM [Flights_Schema].[Tickets] t
JOIN [Flights_Schema].[Fares] f ON f.Fare_ID = t.Fare_ID
WHERE YEAR([Booking_Date]) = 2025
GROUP BY MONTH([Booking_Date]);

-- 8. Airline Revenue Contribution %
SELECT 
    a.name, 
    SUM(fa.price) * 100 / (
        SELECT SUM(price) 
        FROM Flights_Schema.Tickets t2 
        JOIN [Flights_Schema].[Fares] fa2 ON fa2.Fare_ID = t2.Fare_ID
    ) AS Revenue_Percentage
FROM Flights_Schema.Tickets t
JOIN [Flights_Schema].[Fares] fa ON fa.Fare_ID = t.Fare_ID
JOIN [Flights_Schema].[Flights] f ON f.Flight_ID = t.Flight_ID
JOIN [Flights_Schema].[Airlines] a ON a.Airline_Code = f.Airline_Code
GROUP BY a.name;

-- 9. Revenue per Seat Capacity
SELECT 
    dep.City AS Departure_City,
    arr.City AS Arrival_City,
    SUM(fa.Price) / SUM(ac.Seat_Capacity) AS Revenue_Per_Seat
FROM Flights_Schema.Flights f
JOIN Flights_Schema.Tickets t ON t.Flight_ID = f.Flight_ID
JOIN Flights_Schema.Fares fa ON fa.Fare_ID = t.Fare_ID
JOIN Flights_Schema.Aircrafts ac ON ac.Aircraft_ID = f.Aircraft_ID
JOIN Flights_Schema.Airports dep ON dep.Airport_Code = f.Departure_Airport_Code
JOIN Flights_Schema.Airports arr ON arr.Airport_Code = f.Arrival_Airport_Code
GROUP BY dep.City, arr.City
ORDER BY Revenue_Per_Seat DESC;

-------------------------------------------------------------------------------
-- II. OPERATIONAL PERFORMANCE
-------------------------------------------------------------------------------

-- 10. Busiest Weekday Analysis
SELECT  
    COUNT(f.[Flight_Number]) AS Flight_Count,
    DATENAME(WEEKDAY, Scheduled_Departure) AS WeekDayName
FROM [Flights_Schema].[Flights] f
GROUP BY DATENAME(WEEKDAY, Scheduled_Departure)
ORDER BY Flight_Count DESC;

-- 11. Long-Haul Flights (>12h)
SELECT 
    Flight_Number,
    DATEDIFF(HOUR, [Scheduled_Departure], [Scheduled_Arrival]) AS HourDiff,
    a1.City AS Departure_City,
    a2.City AS Arrival_City
FROM [Flights_Schema].[Flights] f
JOIN [Flights_Schema].[Airports] a1 ON a1.Airport_Code = f.Departure_Airport_Code
JOIN [Flights_Schema].[Airports] a2 ON a2.Airport_Code = f.Arrival_Airport_Code
WHERE DATEDIFF(HOUR, [Scheduled_Departure], [Scheduled_Arrival]) > 12;

-- 12. Airline Delay Ranking
SELECT 
    a.Name, 
    AVG(CAST(DATEDIFF(MINUTE, F.Scheduled_Departure, F.Actual_Departure) AS DECIMAL(10, 2))) AS Avg_Delay_Min
FROM [Flights_Schema].[Airlines] a
JOIN [Flights_Schema].[Flights] f ON f.Airline_Code = a.Airline_Code
GROUP BY a.Name
ORDER BY Avg_Delay_Min DESC;

-- 13. Delay Statistics (Average, Min, Max, Median)
WITH DelayData AS (
    SELECT DATEDIFF(MINUTE, Scheduled_Departure, Actual_Departure) AS DelayMinutes
    FROM Flights_Schema.Flights
),
MedianValue AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DelayMinutes) OVER () AS MedianDelay
    FROM DelayData
)
SELECT
    AVG(DelayMinutes) AS AvgDelay,
    MIN(DelayMinutes) AS MinDelay,
    MAX(DelayMinutes) AS MaxDelay,
    (SELECT TOP 1 MedianDelay FROM MedianValue) AS MedianDelay
FROM DelayData;

-- 14. Cancellation Rate by Airline
SELECT
    a.Name AS AirlineName,
    COUNT(CASE WHEN f.Status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*) AS Cancellation_Percent
FROM Flights_Schema.Airlines a
JOIN Flights_Schema.Flights f ON f.Airline_Code = a.Airline_Code
GROUP BY a.Name
ORDER BY Cancellation_Percent DESC;

-------------------------------------------------------------------------------
-- III. PASSENGER ANALYTICS
-------------------------------------------------------------------------------

-- 15. High-Value Frequent Flyers (Gold/Platinum with 10+ tickets)
SELECT * FROM (
    SELECT 
        p.First_Name + ' ' + p.Last_Name AS FullName,
        p.Passenger_ID,
        COUNT([Ticket_Number]) AS count_of_tickets,
        p.Frequent_Flyer_Status
    FROM [Flights_Schema].[Passengers] p
    JOIN [Flights_Schema].[Tickets] t ON t.Passenger_ID = p.Passenger_ID
    GROUP BY p.First_Name, p.Last_Name, p.Frequent_Flyer_Status, p.Passenger_ID
) AS Sub
WHERE Frequent_Flyer_Status IN ('Gold', 'Platinum') AND count_of_tickets > 10;

-- 16. Revenue Generated per Passenger
SELECT  
    p.Passenger_ID,
    p.First_Name + ' ' + p.Last_Name AS FullName,
    SUM(fa.Price) AS Total_Value
FROM Flights_Schema.Passengers p
JOIN Flights_Schema.Tickets t ON t.Passenger_ID = p.Passenger_ID
JOIN Flights_Schema.Fares fa ON fa.Fare_ID = t.Fare_ID
GROUP BY p.Passenger_ID, p.First_Name, p.Last_Name
ORDER BY Total_Value DESC;

-- 17. Most Frequent Route per Passenger
WITH PassengerRoutes AS (
    SELECT  
        p.Passenger_ID,
        p.First_Name + ' ' + p.Last_Name AS FullName,
        f.Departure_Airport_Code,
        f.Arrival_Airport_Code,
        COUNT(*) AS RouteCount
    FROM Flights_Schema.Passengers p
    JOIN Flights_Schema.Tickets t ON t.Passenger_ID = p.Passenger_ID
    JOIN Flights_Schema.Flights f ON f.Flight_ID = t.Flight_ID
    GROUP BY p.Passenger_ID, p.First_Name, p.Last_Name, f.Departure_Airport_Code, f.Arrival_Airport_Code
),
RankedRoutes AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Passenger_ID ORDER BY RouteCount DESC) AS rn
    FROM PassengerRoutes
)
SELECT 
    rr.Passenger_ID, rr.FullName, dep.City AS DepartureCity, arr.City AS ArrivalCity, rr.RouteCount
FROM RankedRoutes rr
JOIN Flights_Schema.Airports dep ON dep.Airport_Code = rr.Departure_Airport_Code
JOIN Flights_Schema.Airports arr ON arr.Airport_Code = rr.Arrival_Airport_Code
WHERE rr.rn = 1;

-- 18. Passenger Segmentation by Booking Class
SELECT  
    f.Booking_Class,
    COUNT(DISTINCT t.Passenger_ID) AS NumPassengers
FROM Flights_Schema.Tickets t
JOIN Flights_Schema.Fares f ON f.Fare_ID = t.Fare_ID
GROUP BY f.Booking_Class
ORDER BY NumPassengers DESC;

-------------------------------------------------------------------------------
-- IV. CREW ANALYTICS
-------------------------------------------------------------------------------

-- 19. Most Active Crew Member
SELECT 
    m.First_Name + ' ' + m.Last_Name AS FullName,
    COUNT(*) AS Count_of_Flights 
FROM [Flights_Schema].[Crew_Members] m
JOIN [Flights_Schema].[Flight_Crew] c ON c.Crew_ID = m.Crew_ID 
GROUP BY m.First_Name, m.Last_Name 
ORDER BY Count_of_Flights DESC;

-- 20. Top 3 Crew Positions by Activity
SELECT TOP 3 
    CM.Position,
    COUNT(FC.Flight_ID) AS Total_Flights_Participated
FROM Flights_Schema.Crew_Members AS CM
JOIN Flights_Schema.Flight_Crew AS FC ON CM.Crew_ID = FC.Crew_ID
GROUP BY CM.Position
ORDER BY Total_Flights_Participated DESC;

-- 21. Crew Experience Rank in Flights
WITH CrewExperience AS (
    SELECT Crew_ID, COUNT(Flight_ID) AS Experience_Flights_Count 
    FROM Flights_Schema.Flight_Crew
    GROUP BY Crew_ID
)
SELECT
    FC.Flight_ID,
    CM.First_Name + ' ' + CM.Last_Name AS Crew_FullName,
    CM.Position,
    CE.Experience_Flights_Count,
    RANK() OVER (PARTITION BY FC.Flight_ID ORDER BY CE.Experience_Flights_Count DESC) AS Experience_Rank_in_Flight
FROM Flights_Schema.Flight_Crew AS FC
JOIN Flights_Schema.Crew_Members AS CM ON FC.Crew_ID = CM.Crew_ID
JOIN CrewExperience AS CE ON FC.Crew_ID = CE.Crew_ID
ORDER BY FC.Flight_ID, Experience_Rank_in_Flight;

-------------------------------------------------------------------------------
-- V. BOOKING AGENT ANALYTICS
-------------------------------------------------------------------------------

-- 22. Top Sales Agent by Revenue
SELECT 
    SUM(price) AS TotalSum, 
    Agent_Name 
FROM [Flights_Schema].[Booking_Agents] b
JOIN [Flights_Schema].[Tickets] t ON t.Agent_ID = b.Agent_ID
JOIN [Flights_Schema].[Fares] f ON f.Fare_ID = t.Fare_ID
GROUP BY Agent_Name
ORDER BY TotalSum DESC;

-- 23. Average Ticket Price by Agent
SELECT 
    b.Agent_Name, 
    AVG(price) AS Average_Price 
FROM [Flights_Schema].[Booking_Agents] b
JOIN [Flights_Schema].[Tickets] t ON t.Agent_ID = b.Agent_ID
JOIN [Flights_Schema].[Fares] f ON f.Fare_ID = t.Fare_ID
GROUP BY b.Agent_Name;

-- 24. Monthly Agent Sales Growth Trend
WITH MonthlyAgentSales AS (
    SELECT
        b.Agent_Name,
        FORMAT(Flt.Scheduled_Departure, 'yyyy-MM') AS Sale_YearMonth,
        SUM(f.Price) AS Monthly_Revenue
    FROM Flights_Schema.Booking_Agents AS b
    JOIN Flights_Schema.Tickets AS t ON t.Agent_ID = b.Agent_ID
    JOIN Flights_Schema.Fares AS f ON f.Fare_ID = t.Fare_ID
    JOIN Flights_Schema.Flights AS Flt ON t.Flight_ID = Flt.Flight_ID
    GROUP BY b.Agent_Name, FORMAT(Flt.Scheduled_Departure, 'yyyy-MM')
),
SalesWithPrevious AS (
    SELECT
        Agent_Name, Sale_YearMonth, Monthly_Revenue,
        LAG(Monthly_Revenue, 1, 0) OVER (PARTITION BY Agent_Name ORDER BY Sale_YearMonth) AS Previous_Month_Revenue
    FROM MonthlyAgentSales
)
SELECT
    Agent_Name, Sale_YearMonth, Monthly_Revenue, Previous_Month_Revenue,
    CASE 
        WHEN Previous_Month_Revenue = 0 THEN NULL 
        ELSE (Monthly_Revenue - Previous_Month_Revenue) / Previous_Month_Revenue * 100 
    END AS Growth_Rate_Percent
FROM SalesWithPrevious
ORDER BY Agent_Name, Sale_YearMonth;