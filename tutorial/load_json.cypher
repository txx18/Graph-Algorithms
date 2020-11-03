CALL apoc.load.json("file:///person.json")
YIELD value
RETURN value;

CALL apoc.load.json("file:///person.json")
YIELD value
MERGE (p:Person {name: value.name})
SET p.age = value.age
WITH p, value
UNWIND value.children AS child
MERGE (c:Person {name: child})
MERGE (c)-[:CHILD_OF]->(p);

WITH "https://api.stackexchange.com/2.2/questions?pagesize=100&order=desc&sort=creation&tagged=neo4j&site=stackoverflow&filter=!5-i6Zw8Y)4W7vpy91PMYsKM-k9yzEsSC1_Uxlf" AS url
CALL apoc.load.json(url) YIELD value
UNWIND value.items AS item
RETURN item.title, item.owner, item.creation_date, keys(item)
LIMIT 5;

WITH
  'https://api.stackexchange.com/2.2/questions?pagesize=100&order=desc&sort=creation&tagged=neo4j&site=stackoverflow&filter=!5-i6Zw8Y)4W7vpy91PMYsKM-k9yzEsSC1_Uxlf'
  AS url
CALL apoc.load.json(url) YIELD value
UNWIND value.items AS q
MERGE (question:Question {id: q.question_id})
  ON CREATE SET question.title = q.title, question.share_link = q.share_link, question.favorite_count = q.favorite_count

FOREACH (tagName IN q.tags |
  MERGE (tag:Tag {name: tagName})
  MERGE (question)-[:TAGGED]->(tag)
)

FOREACH (a IN q.answers |
  MERGE (question)<-[:ANSWERS]-(answer:Answer {id: a.answer_id})
  MERGE (answerer:User {id: a.owner.user_id})
    ON CREATE SET answerer.display_name = a.owner.display_name
  MERGE (answer)<-[:PROVIDED]-(answerer)
)
WITH *
  WHERE NOT q.owner.user_id IS NULL
MERGE (owner:User {id: q.owner.user_id})
  ON CREATE SET owner.display_name = q.owner.display_name
MERGE (owner)-[:ASKED]->(question);

WITH
  'https://api.stackexchange.com/2.2/questions?pagesize=100&order=desc&sort=creation&tagged=neo4j&site=stackoverflow&filter=!5-i6Zw8Y)4W7vpy91PMYsKM-k9yzEsSC1_Uxlf'
  AS url
CALL apoc.load.json(url, '$.items[?(@.answer_count>0)].answers[*]') YIELD value
RETURN value
  LIMIT 5;

WITH
  'https://api.stackexchange.com/2.2/questions?pagesize=100&order=desc&sort=creation&tagged=neo4j&site=stackoverflow&filter=!5-i6Zw8Y)4W7vpy91PMYsKM-k9yzEsSC1_Uxlf'
  AS url
CALL apoc.load.json(url, '$.items[?(@.answer_count>0)].answers[*]') YIELD value
MERGE (a:Answer {id: value.answer_id})
  ON CREATE SET a.accepted = value.is_accepted,
  a.shareLink = value.share_link,
  a.lastActivityDate = value.last_activity_date,
  a.creationDate = value.creation_date,
  a.title = value.title,
  a.score = value.score
MERGE (q:Question {id: value.question_id})
MERGE (a)-[rel:POSTED_TO]->(q)
WITH a AS answer, value.owner AS value
MERGE (u:User {userId: value.user_id})
  ON CREATE SET u.displayName = value.display_name,
  u.userType = value.user_type,
  u.reputation = value.reputation,
  u.userLink = value.link
MERGE (u)-[rel2:SUBMITTED]->(answer)
RETURN count(answer);

MATCH (n)
MATCH()-[r]->()
RETURN n, r;


WITH 'https://api.twitter.com/1.1/search/tweets.json?count=100&result_type=recent&lang=en&q=' AS url_prefix,
     '' AS bearer
//WITH apoc.static.getAll('twitter') AS twitter
CALL apoc.load.jsonParams(
url_prefix + 'oscon+OR+neo4j+OR+%23oscon+OR+%40neo4j',
{Authorization: 'Bearer ' + bearer},
null // payload
)
YIELD value
UNWIND value.statuses AS status

WITH status, status.user AS u, status.entities AS e
RETURN status.id, status.text, u.screen_name,
       [t IN e.hashtags | t.text] AS tags,
       e.symbols,
       [m IN e.user_mentions | m.screen_name] AS mentions,
       [u IN e.urls | u.expanded_url] AS urls;

CALL apoc.load.jsonParams(
'https://neo4j.com/docs/search/',
{method: 'POST'},
apoc.convert.toJson({query: 'subquery', version: '4.0'})
)
