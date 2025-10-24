-- TABLAS CATALOGO
-- Tabla de nombres para los animales: 
CREATE TABLE IF NOT EXISTS cat_nombre_mascota (
  id SMALLINT PRIMARY KEY,
  nombre VARCHAR(40) UNIQUE NOT NULL
);
INSERT INTO cat_nombre_mascota (id, nombre) VALUES
(1,'Luna'),(2,'Orea'),(3,'Simba'),(4,'Milanesa'),(5,'Toby'),(6,'Frida'),(7,'Nacho'),(8,'Churro'),(9,'Kira'),(10,'Batman'),
(11,'Mora'),(12,'Goku'),(13,'Chispa'),(14,'Zoe'),(15,'Coco'),(16,'Tango'),(17,'Kiwi'),(18,'Pancho'),(19,'Nina'),(20,'Jazz'),
(21,'Chloe'),(22,'Croqueta'),(23,'Max'),(24,'Pelusa'),(25,'Tarta'),(26,'Lucho'),(27,'Teddy'),(28,'Chocobo'),(29,'Greta'),
(30,'Fideo'),(31,'Rocco'),(32,'Lolo'),(33,'Bizcocho'),(34,'Olivia'),(35,'Mimi'),(36,'Zeus'),(37,'Pochoclo'),(38,'Candy'),
(39,'Thor'),(40,'Mateo'),(41,'Gala'),(42,'Pepe'),(43,'Romeo'),(44,'Chocotorta'),(45,'Titi'),(46,'Dino'),(47,'Yoda'),
(48,'Taco'),(49,'Lenny'),(50,'Manteca'),(51,'Fiona'),(52,'Ragnar'),(53,'Lia'),(54,'Jack'),(55,'Sol'),(56,'Pepa'),(57,'Chiquito'),
(58,'Maggie'),(59,'Rita'),(60,'Luli'),(61,'Ciro'),(62,'Tina'),(63,'Messi'),(64,'Panqueque'),(65,'Zaira'),(66,'Bongo'),(67,'India'),
(68,'Nico'),(69,'Daisy'),(70,'Bruno'),(71,'Alfajor'),(72,'Chimichurri'),(73,'Pipo'),(74,'Bimba'),(75,'Turrón'),(76,'Bella'),
(77,'Estrella'),(78,'Chester'),(79,'Tommy'),(80,'Sasha'),(81,'Lola'),(82,'Benji'),(83,'Maya'),(84,'Mayoneso'),(85,'Cali'),
(86,'Duke'),(87,'Oreo'),(88,'Galleta'),(89,'Mostaza'),(90,'Leonor'),(91,'Canelita'),(92,'Ñoqui'),(93,'Choclo'),(94,'Pochito'),
(95,'Lunares'),(96,'Tobito'),(97,'Mochi'),(98,'Pistacho'),(99,'Pumba'),(100,'Nube'),(101,'Tornado'),(102,'Cereza'),(103,'Hijo'),
(104,'Batata'),(105,'Turrita'),(106,'Gofio'),(107,'Muffin'),(108,'Cactus'),(109,'Trufa'),(110,'Cumbia'),(111,'Pitusa'),
(112,'Chicle'),(113,'Piruleta'),(114,'Gominola'),(115,'Lucio'),(116,'Pochi'),(117,'Chispi'),(118,'Zanahoria'),(119,'Osito'),
(120,'Pancito'),(121,'Chispon'),(122,'Cachito'),(123,'Trompita'),(124,'Peludín'),(125,'Chisquín'),(126,'Mochilita'),(127,'Marilu'),
(128,'Tornillito'),(129,'Chiscoreta'),(130,'Peluche');

-- Tabla Especie: Cada especie tiene un id y un nombre único: 
CREATE TABLE IF NOT EXISTS especie (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE
);

-- Tabla Raza: 
CREATE TABLE IF NOT EXISTS raza (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  especie_id INT UNSIGNED NOT NULL,
  nombre VARCHAR(80) NOT NULL,
  FOREIGN KEY (especie_id) REFERENCES especie(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Listas de especies/razas elegidas:
-- Especies
INSERT INTO especie (nombre) VALUES
('Perros'),('Gatos'),('Conejos'),('Roedores'),('Caballos'),('Aves'),('Reptiles');

-- Razas/variedades
-- Perros (id especie = 1)
INSERT INTO raza (especie_id, nombre) VALUES
(1,'Labrador Retriever'),(1,'Bulldog'),(1,'Caniche'),
(1,'Pastor Alemán'),(1,'Chihuahua'),(1,'Beagle'),(1,'Salchicha');

-- Gatos (id especie = 2)
INSERT INTO raza (especie_id, nombre) VALUES
(2,'Persa'),(2,'Siamés'),(2,'Maine Coon'),(2,'Bengalí'),
(2,'Azul Ruso'),(2,'Sin pelo'),(2,'Europeo común');

-- Conejos (id especie = 3)
INSERT INTO raza (especie_id, nombre) VALUES
(3,'Holland Lop'),(3,'Mini Rex'),(3,'Conejo enano'),
(3,'Angora'),(3,'Cabeza de león');

-- Roedores (id especie = 4)
INSERT INTO raza (especie_id, nombre) VALUES
(4,'Hámster'),(4,'Cobayo'),(4,'Ratón doméstico'),(4,'Rata doméstica');

-- Caballos (id especie = 5)
INSERT INTO raza (especie_id, nombre) VALUES
(5,'Pura sangre inglés'),(5,'Árabe'),(5,'Criollo argentino'),
(5,'Appaloosa'),(5,'Cuarto de milla');

-- Aves (id especie = 6)
INSERT INTO raza (especie_id, nombre) VALUES
(6,'Periquito'),(6,'Cotorra argentina'),(6,'Agapornis'),
(6,'Loro amazónico'),(6,'Guacamayo'),(6,'Canario'),(6,'Ninfa');

-- Reptiles (id especie = 7)
INSERT INTO raza (especie_id, nombre) VALUES
(7,'Iguana verde'),(7,'Gecko leopardo'),(7,'Dragón barbudo'), 
(7,'Serpiente del maíz'),(7,'Tortuga terrestre'),(7,'Tortuga acuática');

-- dueño
CREATE TABLE IF NOT EXISTS cat_nombre (
  id SMALLINT PRIMARY KEY,
  nombre VARCHAR(40) UNIQUE NOT NULL
);

INSERT INTO cat_nombre (id, nombre) VALUES
(1,'Astrid'),(2,'Carina'),(3,'Andrea'),(4,'Estefania'),(5,'Carolina'),(6,'Martín'),(7,'Paula'),(8,'Diego'),(9,'Lucía'),(10,'Federico'),
(11,'Camila'),(12,'Gabriel'),(13,'Micaela'),(14,'Pedro'),(15,'Victoria'),(16,'Ezequiel'),(17,'Mariana'),(18,'Iván'),(19,'Florencia'),
(20,'Hernán'),(21,'Agustina'),(22,'Tomás'),(23,'Valentina'),(24,'Mateo'),(25,'Julieta'),(26,'Nicolás'),(27,'Milagros'),(28,'Facundo'),
(29,'Brenda'),(30,'Santiago'),(31,'Malena'),(32,'Joaquín'),(33,'Celeste'),(34,'Franco'),(35,'Ailén'),(36,'Emilia'),(37,'Ramiro'),(38,'Martina'),
(39,'Benjamín'),(40,'Cecilia'),(41,'Ignacio'),(42,'Rocío'),(43,'Agustín'),(44,'Bianca'),(45,'Leandro'),(46,'Abril'),(47,'Gonzalo'),(48,'Melina'),
(49,'Lautaro'),(50,'Noelia'),(51,'Esteban'),(52,'Carla'),(53,'Maximiliano'),(54,'Antonella'),(55,'Pablo'),(56,'Josefina'),(57,'Andrés'),(58,'Daniela'),
(59,'Fernando'),(60,'Ariana'),(61,'Ricardo'),(62,'Lorena'),(63,'Cristian'),(64,'Vanesa'),(65,'Matías'),(66,'Tamara'),(67,'Alejandro'),(68,'María'),(69,'Sebastián'),
(70,'Claudia'),(71,'Raúl'),(72,'Patricia'),(73,'Eduardo'),(74,'Gabriela'),(75,'Hugo'),(76,'Verónica'),(77,'Julián'),(78,'Silvina'),(79,'Axel'),(80,'Graciela'),
(81,'Damián'),(82,'Miriam'),(83,'Bruno'),(84,'Norma'),(85,'Kevin'),(86,'Sandra'),(87,'Nahuel'),(88,'Lidia'),(89,'Ulises'),(90,'Mirta'),(91,'Elías'),(92,'Viviana'),
(93,'Simón'),(94,'Estela'),(95,'Alan'),(96,'Beatriz'),(97,'Mauricio'),(98,'Alejandra'),(99,'Oscar'),(100,'Marcos');

-- Veterinarias y sus 4 sedes:
CREATE TABLE IF NOT EXISTS veterinaria_cat (
  id TINYINT PRIMARY KEY,
  nombre VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO veterinaria_cat (id,nombre) VALUES
(1,'Sede Quilmes'),
(2,'Sede La Plata'),
(3,'Sede Coghlan'),
(4,'Sede Tortuguitas');
