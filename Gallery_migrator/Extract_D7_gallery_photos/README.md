Typy obsahu:
SELECT DISTINCT `type` FROM `node` WHERE 1;

Zoznam media galerii:
SELECT * FROM `node` WHERE type="media_gallery";

Zoznam obrazkov v galeriach podla cisla galerie s cislom obrazku
SELECT A.nid, B.fid, A.title, C.uri FROM `node` as A, `file_usage` as B, `file_managed` as C WHERE A.type="media_gallery" AND A.nid=B.id AND B.fid=C.fid ORDER BY A.nid;



