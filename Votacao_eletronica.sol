// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Votacao {
    //Variaveis
    struct voto{
        address endEleitor; //endereço de quem votou
        bool escolha;//Variável auxiliar pra ajudar na auditoria (Escolheu?)
    }

    struct eleitor{
        string nomeEleitor;//Nome do participante
        bool votou; // True = se votou ; False = se não votou
    }

    //Inicializando as variaveis que auxiliarão em algumas contagens
    uint private resultParcial = 0; // Contagem do resultado não poderá ser vista antes do fim da apuração
    uint public resultFinal = 0; // Resultado final da votação para tal contrato
    uint public qtdEleitores = 0; //Total de participantes
    uint public qtdVotos = 0; //Total de votos

    //strings
    string public proposta; //txt da proposta do contrato de votação
    string public nomeVotacao; //Nome do contrato de votaçao

    //Endereço   
    address public endVotacao; // Endereço da contrato de votação

    //Mapeamento
    mapping(uint => voto) private votos; //hash table privada do votos, o mapeamento eh feito de modo privado, ou seja, ngm sabe como foi mapeado os votos, pra manter o sigilo do voto
    mapping(address => eleitor) public registroEleitoral;//Hash table pública dos votantes, ou seja, é público fazer o mapeamento do registro eleitoral

    //Enum
    enum State {Criado, Votando, Finalizado}//Auxilia em delimitar as etapas do voto
    State public state;

    //Funções

    //Criar um contrato de votação
    constructor( string memory _nomeVotacao, string memory _proposta){
        endVotacao = msg.sender;//Endereço do Dono do contrato
        nomeVotacao = _nomeVotacao;
        proposta = _proposta;

        state = State.Criado;
    }

    //Adicionar participante
    function addEleitor(address _endEleitor, string memory _nomeEleitor)public{
        //verifica se ja foi criado um contrato e se quem ta adicionando eh o dono do contrato
        if(state == State.Criado && (msg.sender == endVotacao)){
            eleitor memory v;
            v.nomeEleitor = _nomeEleitor;
            v.votou = false; //Ao add, seta como se o participante ainda não votou 
            registroEleitoral[_endEleitor] = v;//Fazer o endereço do participante ser o registro eleitoral dele, pois é único 
            qtdEleitores++; //Add na contagem de participantes da votação
        }
    }
      
    //Mudar de estado para começar a votação
    function iniciarVotacao()public{
        //verifica se ja foi criado um contrato e se quem ta adicionando eh o dono do contrato
        if(state == State.Criado && (msg.sender == endVotacao)){
            state = State.Votando; //Começa a votação, sendo o dono do contrato responsável por isso
        }
    }

    //Votando 
    function votacao(bool _escolha)public returns (bool votou) {// retorna os participantes que foram registrados se votaram ou não no contrato
        //verifica se ja foi foi autorizado a votação
        if(state == State.Votando){
            bool found = false; //seta como se ninguem votou
            
            //Se votou em algo válido
            if(bytes(registroEleitoral[msg.sender].nomeEleitor).length !=0 && !(registroEleitoral[msg.sender].votou)){
                registroEleitoral[msg.sender].votou = true; // Agora ele votou, e esta localizado no registro eleitoral dele
                voto memory v;
                v.endEleitor = msg.sender;
                v.escolha = _escolha;//O participante no Votacao escolhe true ou false

                //Auditando o voto
                if(_escolha){//se ele votou a favor do contrato
                    resultParcial++;//Add na contagem dos votos a favor
                }

                votos[qtdVotos] = v;// No mapeamento de votos, tal voto vai ser alocado em forma crescente (1,2,3...)
                qtdVotos++;// add na contagem dos votos
                found = true; //Alguem votou
            }

            return found;
        }
    }

    //Finalizando a votação
    function finalizarVotacao()public{
        //verifica se ja estava em votação o contrato, para assim finalizar e se quem ta finalizando eh o dono do contrato
        if(state == State.Votando && (msg.sender == endVotacao)){
            state =  State.Finalizado;
            //Conhecendo a contagem final
            resultFinal = resultParcial;
        }
    }
}
