MATCH (n)
DETACH DELETE n;

CREATE (matrix:Movie {title: 'The Matrix', released: 1997})
CREATE (cloudAtlas:Movie {title: 'Cloud Atlas', released: 2012})
CREATE (forrestGump:Movie {title: 'Forrest Gump', released: 1994})
CREATE (keanu:Person {name: 'Keanu Reeves', born: 1964})
CREATE (robert:Person {name: 'Robert Zemeckis', born: 1951})
CREATE (tom:Person {name: 'Tom Hanks', born: 1956})
CREATE (tom)-[:ACTED_IN {roles: ['Forrest']}]->(forrestGump)
CREATE (tom)-[:ACTED_IN {roles: ['Zachry']}]->(cloudAtlas)
CREATE (robert)-[:DIRECTED]->(forrestGump);

MATCH (m:Movie)
  WHERE m.title = 'The Matrix'
RETURN m;

MATCH (m:Movie {title: 'The Matrix'})
RETURN m;

MATCH (p:Person)-[r:ACTED_IN]->(m:Movie)
  WHERE p.name =~ 'K.+' OR m.released > 2000 OR 'Neo' IN r.roles
RETURN p, r, m;

MATCH (p:Person)-[:ACTED_IN]->(m)
  WHERE NOT (p)-[:DIRECTED]->()
RETURN p, m;

MATCH (p:Person)
return p, p.name as name, toUpper(p.name), coalesce(p.nickname, "n/a") as nickname,
       {name: p.name, label:head(labels(p))} as person;