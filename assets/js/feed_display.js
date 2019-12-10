import React, { useEffect, useState, useReducer, useMemo } from "react";
import { connectChannel } from "./socket";
import {
  VictoryChart,
  VictoryTheme,
  VictoryLine,
  VictoryScatter,
  VictoryAxis
} from "victory";
import { format } from "date-fns";
import axios from "axios";

const reducer = (state, action) => {
  switch (action.type) {
    case "set_initial":
      return Object.entries(action.payload)
        .map(([name, data]) => ({
          [name]: {
            ticks: data.map(transformMetric)
          }
        }))
        .reduce((acc, curr) => ({
          ...acc,
          ...curr
        }));

    case "set_history":
      const { payload } = action;

      console.log(payload);
      console.log(state);

      return {
        ...state,
        [payload.name]: {
          ...state[payload.name],
          history: {
            ...payload
          }
        }
      };

    case "add_metric":
      const { name } = action.payload;
      const existingArray = (state[name] && state[name].ticks) || [];
      const newArray =
        existingArray.length >= 5
          ? [...existingArray.slice(1), transformMetric(action.payload)]
          : [...existingArray, transformMetric(action.payload)];

      return {
        ...state,
        [name]: {
          ...state[name],
          ticks: newArray
        }
      };
    default:
      throw new Error();
  }
};

const transformMetric = metric => {
  const { created_at, value } = metric;

  return {
    x: formatDate(created_at),
    y: value
  };
};

const formatDate = createdAt => format(new Date(createdAt), "mm:ss");

const FeedDisplay = ({ feed }) => {
  const [channel, setChannel] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [didError, setDidError] = useState(false);
  const [groupedMetrics, dispatch] = useReducer(reducer, {});

  useEffect(() => {
    const connected = connectChannel(feed);
    setChannel(connected);
    connected
      .join()
      .receive("ok", resp => {
        dispatch({ type: "set_initial", payload: resp });
        setIsConnected(true);
      })
      .receive("error", () => {
        setIsConnected(false);
        setDidError(true);
      });

    connected.onClose(() => {
      setIsConnected(false);
    });

    connected.onError(() => {
      setDidError(true);
    });

    return () => {
      connected.leave();
    };
  }, [feed]);

  const getHistory = (source, name) => {
    axios
      .get(
        `http://mph-collector-01.local:4000/api/metrics/${source}/${name}/history`
      )
      .then(({ data }) => {
        dispatch({ type: "set_history", payload: { source, name, ...data } });
      });
  };

  useEffect(() => {
    if (!channel) return;
    channel.on("metric_added", newInfo => {
      const { name, source } = newInfo;
      getHistory(source, name);
      dispatch({ type: "add_metric", payload: { ...newInfo } });
    });
  }, [channel]);

  return (
    <div
      style={{
        height: "100%",
        display: "flex",
        flexWrap: "wrap",
        width: "100%",
        alignItems: "center",
        justifyContent: "center"
      }}
    >
      {Object.entries(groupedMetrics).map(([source, data]) => (
        <MetricHistoryChart source={source} key={source} data={data} />
      ))}
    </div>
  );
};

const domainFromLast24Hours = ({ min, max }) => {
  console.log([min * 0.99, max * 1.01]);
  return [min * 0.99, max * 1.01];
};

const MetricHistoryChart = ({
  data: { ticks: chartData, history = {} },
  source
}) => {
  const { all_time, last_24 } = history;
  return (
    <div style={{ minWidth: 600 }}>
      <header>
        <h2>{source}</h2>
        {all_time && last_24 && (
          <>
            <p>Statistics:</p>
            <details>
              <summary>Last 24 Hours</summary>
              <p>Avg: {last_24.avg}</p>
              <p>Min: {last_24.min}</p>
              <p>Max: {last_24.max}</p>
            </details>
            <details>
              <summary>All Time</summary>
              <p>Avg: {all_time.avg}</p>
              <p>Min: {all_time.min}</p>
              <p>Max: {all_time.max}</p>
            </details>
          </>
        )}
      </header>
      <main>
        <VictoryChart
          animate={{
            duration: 1500,
            onExit: {
              duration: 500,
              before: () => ({
                _y: 0
              })
            }
          }}
          theme={VictoryTheme.grayscale}
        >
          <VictoryAxis
            domain={
              !!last_24 ? domainFromLast24Hours(last_24) : domains[source]
            }
            dependentAxis
            orientation="left"
            standalone={false}
            style={{ grid: { stroke: "rgba(60,60,60,0.2)" } }}
          />
          <VictoryAxis
            standalone={false}
            style={{
              grid: {
                stroke: "rgba(60,60,60,1)",
                strokeWidth: 1
              },
              axis: {
                stroke: "rgba(225, 255, 255, 1)",
                strokeWidth: 0
              },
              ticks: {
                strokeWidth: 0
              }
            }}
          />
          <VictoryLine
            width={600}
            style={{
              data: { stroke: "#c43a31" }
            }}
            data={chartData}
          />
          <VictoryScatter
            width={600}
            data={chartData}
            samples={25}
            size={5}
            style={{
              data: { fill: "#c43a31" }
            }}
          />
        </VictoryChart>
      </main>
    </div>
  );
};

const domains = {
  temp: [65, 75],
  humidity: [35, 45]
};

export default FeedDisplay;
