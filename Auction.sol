// SPDX-License-Identifier: MIT
// Se especifica la licencia bajo la cual se distribuye el contrato

pragma solidity 0.8.25;
// Se indica la versión de Solidity que se utilizará para compilar el contrato

contract Subasta {
    // Se declara el contrato de subasta

    // Se declara un tipo enumerado para el estado de la subasta, que puede ser "Activa" o "Vendida"
    enum EstadoSubasta {Activa, Vendida}

    // Se define una estructura para los elementos de la subasta
    struct ElementoSubasta {
        string nombre; // Nombre del producto en subasta
        uint256 precioInicial; // Precio inicial del producto
        uint256 precioActual; // Precio actual del producto
        uint256 fechaInicio; // Fecha de inicio de la subasta (en marca de tiempo Unix)
        uint256 duracion; // Duración de la subasta en días
        address payable creador; // Dirección del creador de la subasta
        address payable propietario; // Dirección del propietario actual del producto
        EstadoSubasta estado; // Estado actual de la subasta
    }

    // Se declara un mapeo que asocia direcciones con arrays de elementos de subasta
    mapping (address => ElementoSubasta[]) public subastas;

    // Eventos
    event NuevaSubasta(
        address vendedor, 
        uint256 indiceProducto, 
        string nombreProductoVendido, 
        uint256 precioInicial, 
        uint256 fechaInicio, 
        uint256 duracion
    );
    event Oferta(bool secreta, address vendedor, uint256 indiceProducto, address comprador, uint256 cantidad);
    event SubastaFinalizada(address vendedor, string nombreProductoVendido, address nuevoPropietario, uint256 precio);
    event TransferenciaRealizada(address indexed comprador, address indexed vendedor, uint256 cantidad);

    // Función para iniciar una nueva subasta
    function iniciarSubasta(string memory nombreProducto, uint256 precioInicial, uint256 duracion) public{
        ElementoSubasta memory miElementoSubasta = ElementoSubasta({
            nombre: nombreProducto,
            precioInicial: precioInicial,
            precioActual: precioInicial,
            fechaInicio: block.timestamp,
            duracion: duracion * 86400, // Se convierte la duración de días a segundos
            creador: payable(msg.sender), // El creador de la subasta es el iniciador
            propietario: payable(msg.sender), // El iniciador también es el propietario inicial
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

    // Función para realizar una oferta en una subasta existente
    function realizarOferta(bool secreta, address payable vendedor, uint256 indiceProducto, uint256 montoOferta) external payable {
        require(subastas[vendedor][indiceProducto].estado == EstadoSubasta.Activa, "Este producto ya ha sido vendido");
        require(montoOferta > subastas[vendedor][indiceProducto].precioActual, "La oferta no supera la mayor oferta");
        require(msg.sender.balance >= montoOferta, "No tienes suficientes Ethers para realizar esta oferta");

        emit Oferta(secreta, vendedor, indiceProducto, msg.sender, montoOferta);
        subastas[vendedor][indiceProducto].propietario = payable(msg.sender); // Se actualiza el propietario del elemento de subasta
        subastas[vendedor][indiceProducto].precioActual = montoOferta; // Se actualiza el precio actual del elemento de subasta
    }

    // Función para finalizar una subasta
    function finalizarSubasta(uint256 indiceProducto) external payable {
        require(block.timestamp > subastas[msg.sender][indiceProducto].duracion + subastas[msg.sender][indiceProducto].fechaInicio, "El tiempo de la subasta aun no ha finalizado");
        require(subastas[msg.sender][indiceProducto].propietario.balance >= subastas[msg.sender][indiceProducto].precioActual, "Error en la transaccion: Fondos insuficientes");
        subastas[msg.sender][indiceProducto].creador.transfer(msg.value); // Se transfiere el monto a la cuenta del creador
        emit TransferenciaRealizada(
            subastas[msg.sender][indiceProducto].propietario, 
            msg.sender,
            subastas[msg.sender][indiceProducto].precioActual
        );
        subastas[msg.sender][indiceProducto].estado = EstadoSubasta.Vendida; // Se marca la subasta como vendida
        emit SubastaFinalizada(
            msg.sender, 
            subastas[msg.sender][indiceProducto].nombre, 
            subastas[msg.sender][indiceProducto].propietario, 
            subastas[msg.sender][indiceProducto].precioActual
        ); // Se emite el evento de subasta finalizada

   }
}
