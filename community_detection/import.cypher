// tag::neo4j-import-nodes[]
WITH "file:///social-nodes.csv"
AS uri
LOAD CSV WITH HEADERS FROM uri AS row
MERGE (:Library {id: row.id})
// end::neo4j-import-nodes[]

// tag::neo4j-import-relationships[]
WITH "file:///social-relationships.csv"
AS uri
LOAD CSV WITH HEADERS FROM uri AS row
MATCH (source:Library {id: row.src})
MATCH (destination:Library {id: row.dst})
MERGE (source)-[:DEPENDS_ON]->(destination)
// end::neo4j-import-relationships[]

