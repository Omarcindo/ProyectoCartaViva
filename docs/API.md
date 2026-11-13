Endpoints REST :

POST    /api/auth/login                 -> token JWT
GET     /api/restaurantes/mio           -> datos de mi restaurante

GET     /api/categorias                 -> lista (filtrada por restaurante)
POST    /api/categorias
PUT     /api/categorias/:id
DELETE  /api/categorias/:id

GET     /api/productos
POST    /api/productos
PUT     /api/productos/:id
DELETE  /api/productos/:id

GET     /api/mesas
POST    /api/mesas
PUT     /api/mesas/:id                  -> (actualizar posición x/y al mover)
DELETE  /api/mesas/:id
GET     /api/mesas/:token               -> resolver QR -> mesa + restaurante
(público)

POST    /api/pedidos                    -> crear pedido (cliente)
GET     /api/pedidos?estado=pendiente
PATCH   /api/pedidos/:id/estado         -> cambiar estado (cocina/caja)
POST    /api/pedidos/:id/ticket         -> cerrar mesa y generar factura

GET     /api/usuarios (roles admin)
POST    /api/usuarios