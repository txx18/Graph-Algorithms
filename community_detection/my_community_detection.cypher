// 导入数据
WITH 'file:///sw-nodes.csv' AS uri
LOAD CSV WITH HEADERS FROM uri AS row
MERGE (:Library {id: row.id});

WITH 'file:///sw-relationships.csv' AS uri
LOAD CSV WITH HEADERS FROM uri AS row
MATCH (source:Library {id: row.src})
MATCH (destination:Library {id: row.dst})
MERGE (source)-[:DEPENDS_ON]->(destination)

// 三角形计数
CALL gds.alpha.triangles({
  nodeProjection:         'Library',
  relationshipProjection: {
                            depends_on: {
                                          type:        'DEPENDS_ON',
                                          orientation: 'UNDIRECTED'
                                        }
                          }
})
YIELD nodeA, nodeB, nodeC
RETURN gds.util.asNode(nodeA).id AS nodeA,
       gds.util.asNode(nodeB).id AS nodeB,
       gds.util.asNode(nodeC).id AS nodeC;

// 局部聚类系数 & 全局聚类系数
CALL gds.localClusteringCoefficient.stream({
  nodeProjection:         'Library',
  relationshipProjection: {
                            depends_on: {
                                          type:        'DEPENDS_ON',
                                          orientation: 'UNDIRECTED'
                                        }
                          }
})
YIELD nodeId, localClusteringCoefficient
//  WHERE localClusteringCoefficient > 0
RETURN gds.util.asNode(nodeId).id AS Library, localClusteringCoefficient AS LCC
  ORDER BY LCC DESC;


// 强连通分量 （SCC）
// 初始版本是一个一类
CALL gds.alpha.scc.stream({
  nodeProjection:         'Library',
  relationshipProjection: 'DEPENDS_ON'
})
YIELD nodeId, componentId
RETURN componentId AS partition, collect(gds.util.asNode(nodeId).id) AS libraries
  ORDER BY size(libraries) DESC;
// 添加extra节点以形成环
MATCH (py4j:Library {id: 'py4j'})
MATCH (pyspark:Library {id: 'pyspark'})
MERGE (extra:Library {id: 'extra'})
MERGE (py4j)-[:DEPENDS_ON]->(extra)
MERGE (extra)-[:DEPENDS_ON]->(pyspark);
// 再次使用SCC
CALL gds.alpha.scc.stream({
  nodeProjection:         'Library',
  relationshipProjection: 'DEPENDS_ON'
})
YIELD nodeId, componentId
RETURN componentId AS partition, collect(gds.util.asNode(nodeId).id) AS libraries
  ORDER BY size(libraries) DESC;
// 删除extra节点
MATCH (extra:Library {id: 'extra'})
DETACH DELETE extra;

// 弱连通分量（WCC）
CALL gds.wcc.stream({
  nodeProjection:         'Library',
  relationshipProjection: 'DEPENDS_ON'
})
YIELD nodeId, componentId
RETURN componentId, collect(gds.util.asNode(nodeId).id) AS libraries
  ORDER BY size(libraries) DESC;

// 标签传播算法
// 有向图
CALL gds.labelPropagation.stream({
  nodeProjection:         'Library',
  relationshipProjection: 'DEPENDS_ON',
  maxIterations:          10
})
YIELD nodeId, communityId
RETURN communityId AS label,
       collect(gds.util.asNode(nodeId).id) AS libraries
  ORDER BY size(libraries) DESC;
// 无向图
CALL gds.labelPropagation.stream({
  nodeProjection:         'Library',
  relationshipProjection: {
                            DEPENDS_ON: {
                                          type:        'DEPENDS_ON',
                                          orientation: 'UNDIRECTED'
                                        }
                          },
  maxIterations:          10
})
YIELD nodeId, communityId
RETURN communityId AS label,
       collect(gds.util.asNode(nodeId).id) AS libraries
  ORDER BY size(libraries) DESC;


// Louvain Modularity
CALL gds.louvain.stream({
  nodeProjection:                 'Library',
  relationshipProjection:         'DEPENDS_ON',
  includeIntermediateCommunities: true
})
YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).id AS libraries,
       communityId, intermediateCommunityIds;
// 在每个节点保存最终结果
CALL gds.louvain.write({
  nodeProjection:                 'Library',
  relationshipProjection:         'DEPENDS_ON',
  includeIntermediateCommunities: true,
  writeProperty:                  'communities'
});
// 在每个节点保存中间结果
CALL gds.louvain.write({
nodeProjection: 'Library',
relationshipProjection: 'DEPENDS_ON',
includeIntermediateCommunities: false,
writeProperty: 'finalCommunity'
});
// 最终聚类
match (l:Library)
return l.finalCommunity as community, collect(l.id) as libraries
order by size(libraries) desc;
// 中间结果，更细粒度的聚簇
match (l:Library)
return l.communities[0] as community, collect(l.id) as libraries
order by size(libraries) desc;
match (l:Library)
return l.communities[1] as community, collect(l.id) as libraries
order by size(libraries) desc;