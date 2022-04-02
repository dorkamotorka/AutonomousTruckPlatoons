import axios from "axios";

const API_URL = "http://127.0.0.1:5000";

class TruckService {
  saveTruckInfo(searchPrams) {  
    return axios.post(API_URL + "/api/" + "getTruckInfo", searchPrams).then((response) => {
      //    return axios.post(API_URL + "GetTruckInfo/truckFunction", searchPrams).then((response) => {
      console.log(JSON.stringify(response));
    });
  }
}

export default new TruckService();
