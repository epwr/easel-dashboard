/* createComponent.js
 *
 * Author: Eric Power
 *
 * Description:
 *    Provides a single place to easily add and edit the behaviour of dashboard
 *    elements.
 */
"use strict";

const createElement = (type, name, desc, dataTypes) => {
  switch(type) {
  case 'time-series':
    return new TimeSeriesElement(name, desc, dataTypes);
  default:
    console.log("Error: " + type + " element not inplemented.");
    return null;
  }
}

class TimeSeriesElement {

  /*
   *
   *
   */
  constructor(name, desc, dataTypes) {

    let config = {
      type: 'line',
      data: {
        labels: [],
        datasets: []
      }
    }

    dataTypes.forEach((type, index) => {
      config['data']['datasets'][index] = {
        label: type['name'],
        data: [],
        borderColor: type['colour'],
        tension: 0.2,
      }
    });

    this.node = document.createElement("canvas");
    this.chart = new Chart( this.node, config);
  }

  /*
   *
   *
   */
  processUpdate(msg) {

    // Parse daashboard update msg
    const dataType = parseInt(msg.split("->")[0]);
    msg = msg.split("->")[1];

    // Validate
    if (false) { // TODO: Check that the dataType is valid.
      console.log("Error validating dashboard update: " + event.data);
      return;
    }

    // Update Chart
    const newLabel = msg.split('"')[1];
    const newValue = parseFloat(msg.split('"')[3]);
    const data = this.chart.data;
    if (dataType == 0) { // Add a label from the 0th data type
      data.labels.push(newLabel);
    }
    data.datasets[dataType].data.push(newValue); // push another data point
    this.chart.update();

    console.log("Valid dashboard update.");
  }

}
