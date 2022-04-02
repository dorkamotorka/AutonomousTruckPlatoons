//import logo from "./logo.svg";
import TruckService from "./services/truck-service.js";
import Logo from "./truckLogo.png";
import { Image } from "react-bootstrap";
import "./App.css";
import Form from "react-bootstrap/Form";

function App() {
  var textStyle = {
  color : 'black'
  };
  return (
    <div className="App">
      <header className="App-header">
        <div className="header">
          <div className="headerLogo" style={{ width: "auto" }}>
            <Image
              src={Logo}
              height="130px"
            ></Image>
          </div>
          <div className="headerTitle"><h1 style={textStyle}>Autonomous Truck Platoon</h1></div>
        </div>
      </header>
      <div className="body">
        <br />
        <legend>
          <h3>For Cargo Delivery </h3>
        </legend>
        <div className="container-fluid">
          <div className="row">
          <div className="col">
              <div className="bodyValues">
                <Form>
                  <Form.Group controlId="exampleForm.weight">
                    <Form.Label>Select Freight</Form.Label>
                    <Form.Control as="select" controlId="exampleForm.weight" name="weight" id="weight">
                    <option value={100}>100 KG</option>
                    <option value={300}>300 KG</option>
                    <option value={500}>500 KG</option>
                    <option value={1000}>1000 KG</option>
                    <option value={1500}>1500 KG</option>
                    <option value={2000}>2000 KG</option>

                    </Form.Control>
                  </Form.Group>
                  <Form.Group controlId="exampleForm.pickUpLocation">
                    <Form.Label>Select pickUp location </Form.Label>
                    <Form.Control as="select" controlId="exampleForm.pickUpLocation" name="pickUpLocation" id="pickUpLocation">
            <option value="Mitte">Mitte</option>
            <option value="Kurfürstendamm">Kurfürstendamm</option>
            <option value="Berliner Dom">Berliner Dom</option>
            <option value="Hauptbahnhof">Hauptbahnhof</option>
            <option value="Grunewald">Grunewald</option>
            <option value="Britz">Britz</option>
                    </Form.Control>
                  </Form.Group>
                  <Form.Group controlId="exampleForm.dropOffLocation">
                    <Form.Label>Select dropOff location </Form.Label>
                    <Form.Control as="select" controlId="exampleForm.dropOffLocation" name="dropOffLocation" id="dropOffLocation"> 
            <option value="Kurfürstendamm">Kurfürstendamm</option>
            <option value="Mitte">Mitte</option>
            <option value="Berliner Dom">Berliner Dom</option>
            <option value="Hauptbahnhof">Hauptbahnhof</option>
            <option value="Grunewald">Grunewald</option>
            <option value="Britz">Britz</option>

                    </Form.Control>
                  </Form.Group>
             
                </Form>
            
              </div>
           
              <div className="bodyValues">
                
                <button id="btn" type="button" onClick={search}>
                  Search
                </button>
              </div>
            </div>
         
            <div className="col">
              {" "}
              <img src={process.env.PUBLIC_URL + "/map_final.png"} alt="logo" />
            </div>
            </div>
        </div>
      </div>
    </div>
  );
}

const search = (e) => {
  console.log("text print");
  var weight = document.querySelector("#weight").value;
  var pickUpLocation = document.querySelector("#pickUpLocation").value;
  var dropOffLocation = document.querySelector("#dropOffLocation").value;

  var searchPrams = {
    weight: weight,
    pickUpLocation: pickUpLocation,
    dropOffLocation: dropOffLocation,
  };
  console.log(TruckService.saveTruckInfo(searchPrams));
};

export default App;
