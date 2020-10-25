// tag::neo4j-import-nodes[]
WITH 'file:///sw-nodes.csv' AS uri
LOAD CSV WITH HEADERS FROM uri AS row
MERGE (:Library {id: row.id});
// end::neo4j-import-nodes[]

//with 'file:///sw-nodes.csv' as uri
//load csv with headers from uri as row
//merge (:Library {id: row.id})

// tag::neo4j-import-relationships[]
WITH 'file:///sw-relationships.csv' AS uri
LOAD CSV WITH HEADERS FROM uri AS row
MATCH (source:Library {id: row.src})
MATCH (destination:Library {id: row.dst})
MERGE (source)-[:DEPENDS_ON]->(destination);
// end::neo4j-import-relationships[]

//WITH 'file:///sw-relationships.csv' AS uri
//LOAD CSV WITH HEADERS FROM uri AS row
//MATCH (source:Library {id: row.src})
//MATCH (destination:Library {id: row.dst})
//MERGE (source)-[:DEPENDS_ON]->(destination)

