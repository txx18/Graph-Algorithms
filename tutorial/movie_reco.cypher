/*# 用Neo4j进行个性化产品推荐

## 推荐

个性化的产品推荐可以增加转化次数，提高销售率并为用户提供更好的体验。
在此Neo4j浏览器指南中，我们将介绍如何使用电影和电影收视率数据集生成基于图的实时个性化产品推荐，但是这些技术可以应用于许多不同类型的产品或内容。


## 基于图的推荐

生成个性化推荐是图形数据库最常见的用例之一。
使用图形生成建议的一些主要好处包括：
1. 性能。
无索引邻接允许实时计算推荐，确保推荐始终相关并反映最新信息。
2. 数据模型。
标记的属性图模型可轻松组合来自多个来源的数据集，从而使企业能够从先前分离的数据孤岛中释放价值。*/

//- 例子 How many reviews does each Matrix movie have?
MATCH (m:Movie)<-[:RATED]-(u:User)
  WHERE m.title CONTAINS 'Matrix'
WITH m.title AS movie, COUNT(*) AS reviews
RETURN movie, reviews
  ORDER BY reviews DESC
  LIMIT 5;


//## 基于内容的推荐
//推荐与用户正在查看的，相似的，评价较高或以前购买的商品。"Products similar to the product you’re looking at now"
//- 例子
//  - 搜索与电影"Net, The" 有 共同出演or题材or导演的电影 （限定关系长度为2），限制25个电影
MATCH p = (m:Movie {title: 'Net, The'})-[:ACTED_IN|:IN_GENRE|:DIRECTED*2]-()
RETURN p
  LIMIT 25
//    - 限制100个电影

//### 根据共同属性的数量推荐
//#### 根据共同的题材推荐
//  - 搜索与电影"Inception"有共同题材的电影
MATCH (m:Movie)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)
  WHERE m.title = 'Inception'
WITH rec, collect(g.name) AS genres, COUNT(*) AS commonGenres
RETURN rec.title, genres, commonGenres
  ORDER BY commonGenres DESC
  LIMIT 10;
//  - 分解1
// 本来有两种题材
// 这样的查询只能显示一种题材，不限制路径数量直接卡死
MATCH p = (m:Movie)-[:IN_GENRE]->(g:Genre {name: 'Adventure'})<-[:IN_GENRE]-(rec:Movie)
  WHERE m.title = 'Kung Fu Panda 3'
RETURN p
  LIMIT 25

//#### 个性化推荐相似题材的电影
// 推荐，根据用户"Angelica Rodriguez"评分过的电影 题材重叠的数量 推荐，不包括用户已经评分过的电影
// 排序根据score
MATCH (u:User {name: 'Angelica Rodriguez'})-[r:RATED]->(m:Movie),
      (m)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)
  WHERE NOT exists((u)-[:RATED]->(rec))
WITH rec, [g.name, COUNT(*)] AS scores
RETURN rec.title AS recommendation, rec.year AS year,
       collect(scores) AS scoreComponents,
       reduce (s = 0, x IN collect(scores) | s + x[1]) AS score
  ORDER BY score DESC
  LIMIT 10
//  - 分解
// **count(*)如何理解**我觉得是p路径的数量
MATCH p = (u:User {name: 'Angelica Rodriguez'})-[r:RATED]->(m:Movie)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)
  WHERE NOT exists((u)-[:RATED]->(rec))
RETURN p
  LIMIT 25
//  ![](https://gitee.com/txx18/PicGo/raw/master/img/20201031094617.png)

//#### 加权权重，例如题材、演员、导演
// 搜索，与电影"Wizard of Oz, The"相似的电影，题材、演员、导演重叠的数量加权
MATCH (m:Movie)
  WHERE m.title = 'Wizard of Oz, The'
MATCH (m)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)
WITH m, rec, COUNT(*) AS gs
OPTIONAL MATCH (m)<-[:ACTED_IN]-(a:Actor)-[:ACTED_IN]->(rec)
WITH m, rec, gs, count(a) AS as
OPTIONAL MATCH (m)<-[:DIRECTED]-(d:Director)-[:DIRECTED]->(rec)
WITH m, rec, gs, as, count(d) AS ds
RETURN rec.title AS recommendation, (5 * gs) + (3 * as) + (4 * ds) AS score
  ORDER BY score DESC
  LIMIT 100

//### 基于内容的度量-Jaccard相似度
//#### Jaccard相似度
//（也就是那个简单的异质信息网络模型）
//- 题材上的相似度
MATCH (m:Movie {title: 'Inception'})-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(other:Movie)
WITH m, other, count(g) AS intersection, collect(g.name) AS i
MATCH (m)-[:IN_GENRE]->(mg:Genre)
WITH m, other, intersection, i, collect(mg.name) AS s1
MATCH (other)-[:IN_GENRE]->(og:Genre)
WITH m, other, intersection, i, s1, collect(og.name) AS s2
WITH m, other, intersection, s1, s2
WITH m, other, intersection,
  s1 + filter(x IN s2
    WHERE NOT x IN s1) AS union, s1, s2
RETURN m.title, other.title, s1, s2, ((1.0 * intersection) / size(union)) AS jaccard
  ORDER BY jaccard DESC
  LIMIT 100

//- 加上考虑题材、演员、导演
MATCH (m:Movie {title: 'Inception'})-[:IN_GENRE|:ACTED_IN|:DIRECTED]-(t)-[:IN_GENRE|:ACTED_IN|:DIRECTED]-(other:Movie)
WITH m, other, count(t) AS intersection, collect(t.name) AS i
MATCH (m)-[:IN_GENRE|:ACTED_IN|:DIRECTED]-(mt)
WITH m, other, intersection, i, collect(mt.name) AS s1
MATCH (other)-[:IN_GENRE|:ACTED_IN|:DIRECTED]-(ot)
WITH m, other, intersection, i, s1, collect(ot.name) AS s2
WITH m, other, intersection, s1, s2
WITH m, other, intersection,
  s1 + filter(x IN s2
    WHERE NOT x IN s1) AS union, s1, s2
RETURN m.title, other.title, s1, s2, ((1.0 * intersection) / size(union)) AS jaccard
  ORDER BY jaccard DESC
  LIMIT 100

//## 基于协同过滤-利用用户评分
//使用网络中其他用户的首选项，评分和操作来查找要推荐的项目。"Users who bought this thing, also bought that other thing."

//- 例子
// 搜索看过"Crimson Tide"的其他用户评分过的电影，按照
MATCH (m:Movie {title: 'Crimson Tide'})<-[:RATED]-(u:User)-[:RATED]->(rec:Movie)
RETURN rec.title AS recommendation, COUNT(*) AS usersWhoAlsoWatched
  ORDER BY usersWhoAlsoWatched DESC
  LIMIT 25

//### 步骤
//1. 找到相似用户
//2. 假设相似用户有相似喜好

// 搜索用户Misty Williams所有的评分
MATCH (u:User {name: 'Misty Williams'})
MATCH (u)-[r:RATED]->(m:Movie)
RETURN *;

// 搜索用户Misty Williams评分高于平均评分的电影
MATCH (u:User {name: 'Misty Williams'})
MATCH (u)-[r:RATED]->(m:Movie)
WITH u, avg(r.rating) AS average
MATCH (u)-[r:RATED]->(m:Movie)
  WHERE r.rating > average
RETURN *;

//## 基于协同过滤-群体智慧
//### 简单协同过滤

MATCH (u:User {name: 'Cynthia Freeman'})-[:RATED]->(:Movie)<-[:RATED]-(o:User)
MATCH (o)-[:RATED]->(rec:Movie)
  WHERE NOT exists((u)-[:RATED]->(rec))
RETURN rec.title, rec.year, rec.plot
  LIMIT 25

//### 只考虑用户喜欢的题材（喜欢这个题材 - 喜欢这个的电影多）
MATCH (u:User {name: 'Andrew Freeman'})-[r:RATED]->(m:Movie)
WITH u, avg(r.rating) AS mean

MATCH (u)-[r:RATED]->(m:Movie)-[:IN_GENRE]->(g:Genre)
  WHERE r.rating > mean

WITH u, g, COUNT(*) AS score

MATCH (g)<-[:IN_GENRE]-(rec:Movie)
  WHERE NOT exists((u)-[:RATED]->(rec))

RETURN rec.title AS recommendation, rec.year AS year, collect(DISTINCT g.name) AS genres, sum(score) AS sscore
  ORDER BY sscore DESC
  LIMIT 10

//### 协同过滤-相似度度量
//#### 余弦相似度
//- 找到和用户Cynthia Freeman最相似的用户
MATCH (p1:User {name: 'Cynthia Freeman'})-[x:RATED]->(movie)<-[x2:RATED]-(p2:User)
  WHERE p2 <> p1
WITH p1, p2, collect(x.rating) AS p1Ratings, collect(x2.rating) AS p2Ratings
  WHERE size(p1Ratings) > 10
RETURN p1.name AS from,
       p2.name AS to,
       algo.similarity.cosine(p1Ratings, p2Ratings) AS similarity
  ORDER BY similarity DESC

//#### Pearson相似度
//- 找到和用户Cynthia Freeman最相似的用户
MATCH (u1:User {name: 'Cynthia Freeman'})-[r:RATED]->(m:Movie)
WITH u1, avg(r.rating) AS u1_mean

MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
WITH u1, u1_mean, u2, collect({r1: r1, r2: r2}) AS ratings
  WHERE size(ratings) > 10

MATCH (u2)-[r:RATED]->(m:Movie)
WITH u1, u1_mean, u2, avg(r.rating) AS u2_mean, ratings

UNWIND ratings AS r

WITH sum((r.r1.rating - u1_mean) * (r.r2.rating - u2_mean)) AS nom,
     sqrt(sum((r.r1.rating - u1_mean) ^ 2) * sum((r.r2.rating - u2_mean) ^ 2)) AS denom,
     u1, u2
  WHERE denom <> 0

RETURN u1.name, u2.name, nom / denom AS pearson
  ORDER BY pearson DESC
  LIMIT 100

//### 协同过滤-基于近邻的推荐
//- kNN Pearson相似度
MATCH (u1:User {name: 'Cynthia Freeman'})-[r:RATED]->(m:Movie)
WITH u1, avg(r.rating) AS u1_mean

MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
WITH u1, u1_mean, u2, collect({r1: r1, r2: r2}) AS ratings
  WHERE size(ratings) > 10

MATCH (u2)-[r:RATED]->(m:Movie)
WITH u1, u1_mean, u2, avg(r.rating) AS u2_mean, ratings

UNWIND ratings AS r

WITH sum((r.r1.rating - u1_mean) * (r.r2.rating - u2_mean)) AS nom,
     sqrt(sum((r.r1.rating - u1_mean) ^ 2) * sum((r.r2.rating - u2_mean) ^ 2)) AS denom,
     u1, u2
  WHERE denom <> 0

WITH u1, u2, nom / denom AS pearson
  ORDER BY pearson DESC
  LIMIT 10

MATCH (u2)-[r:RATED]->(m:Movie)
  WHERE NOT exists((u1)-[:RATED]->(m))

RETURN m.title, sum(pearson * r.rating) AS score
  ORDER BY score DESC
  LIMIT 25

//- kNN Pearson相似度apoc方法
MATCH (u1:User {name: 'Cynthia Freeman'})-[x:RATED]->(movie:Movie)
WITH u1, algo.similarity.asVector(movie, x.rating) AS u1Vector
MATCH (u2:User)-[x2:RATED]->(movie:Movie)
  WHERE u2 <> u1

WITH u1, u2, u1Vector, algo.similarity.asVector(movie, x2.rating) AS u2Vector
  WHERE size(apoc.coll.intersection([v IN u1Vector | v.category], [v IN u2Vector | v.category])) > 10

WITH u1, u2, algo.similarity.pearson(u1Vector, u2Vector, {vectorType: 'maps'}) AS similarity
  ORDER BY similarity DESC
  LIMIT 10

MATCH (u2)-[r:RATED]->(m:Movie)
  WHERE NOT exists((u1)-[:RATED]->(m))
RETURN m.title, sum(similarity * r.rating) AS score
  ORDER BY score DESC
  LIMIT 25