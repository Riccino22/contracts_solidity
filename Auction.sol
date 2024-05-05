// SPDX-License-Identifier: GPL-3.0
// Se especifica la licencia bajo la cual se distribuye el contrato

pragma solidity 0.8.25;
// Se indica la versión de Solidity que se utilizará para compilar el contrato

contract Subasta {
    // Se declara el contrato de subasta

    enum EstadoSubasta {Activa, Vendida}
    // Se declara un tipo enumerado para el estado de la subasta, que puede ser "Activa" o "Vendida"

    struct ElementoSubasta {
        // Se define una estructura para los elementos de la subasta
        string nombre; // Nombre del producto en subasta
        uint256 precioInicial; // Precio inicial del producto
        uint256 precioActual; // Precio actual del producto
        uint256 fechaInicio; // Fecha de inicio de la subasta (en marca de tiempo Unix)
        uint256 duracion; // Duración de la subasta en días
        address propietario; // Dirección del propietario del producto
        EstadoSubasta estado; // Estado actual de la subasta
        //mapping (address => uint256) ofertas; // Mapeo para almacenar ofertas de compradores
    }

    mapping (address => ElementoSubasta[]) public subastas;
    // Se declara un mapeo que asocia direcciones con arrays de elementos de subasta

    event NuevaSubasta(
        address vendedor, 
        uint256 indiceProducto, 
        string nombreProductoVendido, 
        uint256 precioInicial, 
        uint256 fechaInicio, 
        uint256 duracion
    );
    // Se declara un evento que se emite cuando se inicia una nueva subasta
    event Oferta(address vendedor, uint256 indiceProducto, address comprador, uint256 cantidad);
    event SubastaFinalizada(address vendedor, string nombreProductoVendido, address nuevoPropietario, uint256 precio);
    // Se declara un evento que se emite cuando una subasta finaliza y se vende un producto

    function iniciarSubasta(string memory nombreProducto, uint256 precioInicial, uint256 duracion) public{
        // Función para iniciar una nueva subasta
        ElementoSubasta memory miElementoSubasta = ElementoSubasta({
            // Se crea un nuevo elemento de subasta
            nombre: nombreProducto,
            precioInicial: precioInicial,
            precioActual: precioInicial,
            fechaInicio: block.timestamp,
            duracion: duracion * 86400, // Se convierte la duración de días a segundos
            propietario: msg.sender, // El iniciador de la subasta se convierte en el propietario
            estado: EstadoSubasta.Activa // La subasta se marca como activa
        });
        subastas[msg.sender].push(miElementoSubasta); // Se agrega el elemento de subasta al array correspondiente
        emit NuevaSubasta(
            msg.sender,
            subastas[msg.sender].length - 1,
            nombreProducto, 
            precioInicial,
            block.timestamp, 
            duracion
        ); // Se emite el evento de nueva subasta
    }

    function realizarOferta(address payable vendedor, uint256 indiceProducto, uint256 montoOferta) external payable {
        // Función para realizar una oferta en una subasta existente
        require(subastas[vendedor][indiceProducto].estado == EstadoSubasta.Activa, "Este producto ya ha sido vendido");
        vendedor.transfer(msg.value);
        emit Oferta(vendedor, indiceProducto, msg.sender, montoOferta);
        subastas[vendedor][indiceProducto].propietario = msg.sender; // Se actualiza el propietario del elemento de subasta
        subastas[vendedor][indiceProducto].precioActual = montoOferta; // Se actualiza el precio actual del elemento de subasta
    }

    function finalizarSubasta(uint256 indiceProducto) public {
        // Función para finalizar una subasta
        subastas[msg.sender][indiceProducto].estado = EstadoSubasta.Vendida; // Se marca la subasta como vendida
        emit SubastaFinalizada(
            msg.sender, 
            subastas[msg.sender][indiceProducto].nombre, 
            subastas[msg.sender][indiceProducto].propietario, 
            subastas[msg.sender][indiceProducto].precioActual
        ); // Se emite el evento de subasta finalizada
    }
}

