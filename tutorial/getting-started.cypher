MATCH (n)
DETACH DELETE n;

MATCH (n) REMOVE n;

MATCH (n)- [r] - >()
RETURN n, r;

// *******************
// Patterns in practice
// *******************

// creating data
CREATE (:Movie {title:'The Matrix', released:1997});

CREATE (p:Person {name:'Keanu Reeves', born: 1964})
RETURN p;

CREATE (a:Person {name:'Tom Hanks',
born: 1956})- [r:ACTED_IN {roles:['Forrest']}] - >(m:Movie {title:'Forrest Gump', released: 1994})
CREATE (d:Person {name:'Robert Zemeckis', born: 1951})- [:DIRECTED] - >(m)
RETURN a, d, r, m;

// matching patterns
MATCH (m:Movie)
RETURN m

MATCH (p:Person {name:'Keanu Reeves'})
RETURN p

MATCH (p:Person {name:'Tom Hanks'})- [r:ACTED_IN] - >(m:Movie)
RETURN m.title, r.roles

// attaching structures
// 在已有数据基础上添加，一种方法是match-create，一种方法是merge
MATCH (p:Person {name:'Tom Hanks'})
CREATE (m:Movie {title:'Cloud Atlas', released: 2012})
CREATE (p)- [r:ACTED_IN {roles:['Zachry']}] - >(m)
RETURN p, r, m

// Completing patterns
// merge先查后写
MERGE (m:Movie {title:'Cloud Atlas'})
ON CREATE SET m.released = 2012
RETURN m

MATCH (m:Movie {title:'Cloud Atlas'})
MATCH (p:Person {name:'Tom Hanks'})
MERGE (p)- [r:ACTED_IN] - >(m)
ON CREATE SET r.roles = ['Zachry']
RETURN p, r, m

CREATE (y:Year {year:2014})
MERGE (y)< - [:IN_YEAR] -(m10:Month {month:10})
MERGE (y)< - [:IN_YEAR] -(m11:Month {month:11})
RETURN y, m10, m11

// *******************
// Getting the correct results
// *******************
CREATE (matrix:Movie {title:'The Matrix', released: 1997})
CREATE (cloudAtlas:Movie {title:'Cloud Atlas', released: 2012})
CREATE (forrestGump:Movie {title:'Forrest Gump', released: 1994})
CREATE (keanu:Person {name:'Keanu Reeves', born: 1964})
CREATE (robert:Person {name:'Robert Zemeckis', born: 1951})
CREATE (tom:Person {name:'Tom Hanks', born: 1956})
CREATE (tom)- [:ACTED_IN {roles:['Forrest']}] - >(forrestGump)
CREATE (tom)- [:ACTED_IN {roles:['Zachry']}] - >(cloudAtlas)
CREATE (robert)- [:DIRECTED] - >(forrestGump);

// Filtering results
MATCH (m:Movie)
WHERE m.title = 'The Matrix'
RETURN m;

MATCH (m:Movie {title:'The Matrix'})
RETURN m;

MATCH (p:Person)- [r:ACTED_IN] - >(m:Movie)
WHERE p.name =~ 'K.+' OR m.released > 2000 OR 'Neo' IN r.roles
RETURN p, r, m;

MATCH (p:Person)- [:ACTED_IN] - >(m)
WHERE NOT (p)- [:DIRECTED] - >()
RETURN p, m;

// Returning results
MATCH (p:Person)
RETURN p, p.name AS name, toUpper(p.name), coalesce(p.nickname, 'n/a') AS nickname,
{name:p.name, label:head(labels(p))} AS person;

MATCH (n)
RETURN DISTINCT labels(n) AS Labels;

// Aggregating information
// 聚合
MATCH (:Person)
RETURN count(*) AS people;

MATCH (actor:Person)- [:ACTED_IN] - >(movie:Movie)< - [:DIRECTED] -(director:Person)
RETURN movie, actor, director, count(*) AS collaborations;

// Ordering and pagination
// 排序 & 分页
MATCH (a:Person)- [:ACTED_IN] - >(m:Movie)
RETURN a, count(*) AS appearances
ORDER BY appearances DESC
LIMIT 10;

// Collecting aggregation
// 显示一对多
MATCH (m:Movie)< - [:ACTED_IN] -(a:Person)
RETURN m.title AS movie, collect(a.name) AS cast, count(*) AS actors;

// *******************
// Composing large statements
// *******************

// UNION
// 合并同样格式的结果
MATCH (actor:Person)- [r:ACTED_IN] - >(movie:Movie)
RETURN actor.name AS name, type(r) AS type, movie.title AS title
UNION
MATCH (director:Person)- [r:DIRECTED] - >(movie:Movie)
RETURN director.name AS name, type(r) AS type, movie.title AS title;

MATCH (actor:Person)- [r:ACTED_IN|DIRECTED] - >(movie:Movie)
RETURN actor.name AS name, type(r) AS type, movie.title AS title

// WITH
// 管道
MATCH (person:Person)- [:ACTED_IN] - >(m:Movie)
WITH person, count(*) AS appearances, collect(m.title) AS movies
WHERE appearances > 1
RETURN person.name, appearances, movies

// *******************
// Defining a schema
// *******************

// Using indexes
//This feature is deprecated and will be removed in future versions.
//The create index syntax `CREATE INDEX ON :Label(property)` is deprecated,
// please use `CREATE INDEX FOR (n:Label) ON (n.property)` instead
CREATE INDEX ON:Person(name)

CREATE INDEX ON:Person(name, born)

// 报错
CALL db.indexes
YIELD description, tokenNames, properties, type;

// Using constraints
CREATE CONSTRAINT ON (movie:Movie) ASSERT movie.title IS UNIQUE

CALL db.constraints;

// *******************
// Import data
// *******************
CREATE CONSTRAINT ON (person:Person) ASSERT

