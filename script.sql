-- Delete tables if they exist
DROP 
  TABLE IF EXISTS Completions;
DROP 
  TABLE IF EXISTS Players;
DROP 
  TABLE IF EXISTS Levels;
-- Create tables
CREATE TABLE Players (
  PlayerId INT, 
  Name VARCHAR(50)
);
CREATE TABLE Levels (
  LevelId INT, 
  LevelName VARCHAR(50)
);
CREATE TABLE Completions (PlayerId INT, LevelId INT);
-- Insert 7 players
INSERT INTO Players 
VALUES 
  (1, 'Alex'), 
  (2, 'Beth'), 
  (3, 'Carl'), 
  (4, 'Diana'), 
  (5, 'Erik'), 
  (6, 'Fiona'), 
  (7, 'Greg');
-- Insert 3 levels
INSERT INTO Levels 
VALUES 
  (1, 'Forest'), 
  (2, 'Cave'), 
  (3, 'Castle');
-- Insert completions: 3 players complete all levels, 4 players with different
patterns INSERT INTO Completions 
VALUES 
  -- Alex, Beth, Carl: Completed all 3 levels
  (1, 1), 
  (1, 2), 
  (1, 3), 
  (2, 1), 
  (2, 2), 
  (2, 3), 
  (3, 1), 
  (3, 2), 
  (3, 3), 
  -- Diana: Only completed Forest
  (4, 1), 
  -- Erik: Completed Forest and Cave
  (5, 1), 
  (5, 2), 
  -- Fiona: Only completed Castle
  (6, 3), 
  -- Greg: Completed Forest and Castle
  (7, 1), 
  (7, 3);



SELECT PlayerId FROM Completions WHERE LevelId = 1 -- Forest completers
UNION
SELECT PlayerId FROM Completions WHERE LevelId = 2; -- Cave completers
-- Note: Fiona (6) is excluded - Only completed Castle (Level=3)


SELECT p.PlayerId, p.Name, l.LevelId, l.LevelName
FROM Players p CROSS JOIN Levels l
ORDER BY p.PlayerId, l.LevelId;
-- Result: 7 players × 3 levels = 21 total combinations
-- Shows every player paired with every level (whether completed or not)



SELECT PlayerId FROM Completions WHERE LevelId = 1 -- Forest completers
INTERSECT
SELECT PlayerId FROM Completions WHERE LevelId = 2; -- Cave completers
-- Excluded players:
-- Diana (4): Only completed Forest (Level=1)
-- Fiona (6): Only completed Castle (Level=3)
-- Greg (7): Completed Forest and Castle (Levels=1,3)



SELECT PlayerId FROM Completions WHERE LevelId = 1 -- Forest completers
EXCEPT
SELECT PlayerId FROM Completions WHERE LevelId = 2; -- Cave completers
-- Excluded players:
-- Alex (1), Beth (2), Carl (3), Erik (5) have completed Level=2
-- Fiona (6) has not completed Level=1



SELECT PlayerId
FROM Completions
WHERE LevelId = 1
AND PlayerId NOT IN (
    SELECT PlayerId FROM Completions WHERE LevelId = 2
);



SELECT c1.PlayerId
FROM (SELECT DISTINCT PlayerId FROM Completions WHERE LevelId = 1) c1
LEFT JOIN (SELECT DISTINCT PlayerId FROM Completions WHERE LevelId = 2) c2
ON c1.PlayerId = c2.PlayerId
WHERE c2.PlayerId IS NULL;
-- This filters for players who exist in Forest (c1) but have NO match in Cave (c2)
-- LEFT JOIN keeps all c1 records, setting c2 fields to NULL when no match exists



SELECT DISTINCT PlayerId
FROM Completions c1
WHERE c1.LevelId = 1 -- Forest completers
AND NOT EXISTS (
    SELECT 1 -- The existence of a row matters not the value of it
    FROM Completions c2
    WHERE c2.PlayerId = c1.PlayerId
    AND c2.LevelId = 2 -- Cave completers
);



-- Find players where there does NOT exist a level that they did NOT complete.
SELECT p.PlayerId, p.Name
FROM Players p
WHERE NOT EXISTS ( -- does NOT exist a level
    SELECT 1 -- The existence of a row matters not the value of it
    FROM Levels l
    WHERE NOT EXISTS ( -- did NOT complete
        SELECT 1
        FROM Completions c
        WHERE c.PlayerId = p.PlayerId
        AND c.LevelId = l.LevelId
    )
);



-- If we add 'Difficulty' column in our Level table, then we can address:
-- Find players who completed ALL HARD levels
SELECT p.PlayerId, p.Name
FROM Players p
WHERE NOT EXISTS ( -- First NOT EXISTS can filter levels
    SELECT 1
    FROM Levels l
    WHERE l.Difficulty = 'HARD' -- CONDITION IN FIRST NOT EXISTS
AND NOT EXISTS ( -- Second NOT EXISTS checks completion
    SELECT 1
    FROM Completions c
    WHERE c.PlayerId = p.PlayerId
    AND c.LevelId = l.LevelId
)
);



SELECT p.PlayerId, p.Name
FROM Players p
JOIN Completions c ON p.PlayerId = c.PlayerId
JOIN Levels l ON c.LevelId = l.LevelId
GROUP BY p.PlayerId, p.Name
HAVING COUNT(DISTINCT c.LevelId) = (SELECT COUNT(*) FROM Levels);
-- Why DISTINCT matters: If completions table had duplicates
-- (player completed same level twice), we'd still count correctly



SELECT p.PlayerId, p.Name
FROM Players p
WHERE NOT EXISTS ( -- Empty Set
    SELECT LevelId FROM Levels -- All Levels
    EXCEPT
    SELECT LevelId FROM Completions c WHERE c.PlayerId = p.PlayerId -- Their Completions
);



SELECT PlayerId, Name
FROM Players
WHERE PlayerId IN (
    SELECT c.PlayerId
    FROM Completions c
    WHERE c.LevelId IN (SELECT LevelId FROM Levels) -- Filter valid levels
    GROUP BY c.PlayerId -- Group by player
    HAVING COUNT(DISTINCT c.LevelId) = (SELECT COUNT(*) FROM Levels) -- Count = total
);
-- DISTINCT is crucial - prevents counting duplicate completions