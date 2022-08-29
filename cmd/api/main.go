//
// This is just a template file used for testing and bootstraping!
//
package main

import (
	"context"
	"embed"
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/log/logrusadapter"
	"github.com/kelseyhightower/envconfig"
	"github.com/sirupsen/logrus"

	"github.com/dlpco/go-infrastructure/stnpg"
)

var migrationFS embed.FS

func pingDatabase() {

	fmt.Println("I will reach out to my fellow friend, the database")

	logrus.Debug("Attempting to parse database config from env vars")
	ctx := context.Background()
	pgConfig := stnpg.Config{}
	err := envconfig.Process("", &pgConfig)
	if err != nil {
		logrus.Errorf("Could not parse database config from env: %s", err)
		os.Exit(1)
	}

	logrus.Debugf("Attempting to connect to DB [%s] at [%s] \\o/", pgConfig.DatabaseName, pgConfig.Host)
	pgxPool, err := stnpg.ConnectPgxPool(ctx, stnpg.PgxConfig{
		URL: pgConfig.PoolDSN(),
		Logging: stnpg.PgxLog{ // the log instance used by the pgx driver
			Logger: logrusadapter.NewLogger(logrus.New()),
			Level:  pgx.LogLevelError,
		},
	})
	if err != nil {
		logrus.Errorf("Could not connect to database :(")
		panic(err)
	}

	defer pgxPool.Close()

	response, err := pgxPool.Query(ctx, "SELECT version();")
	if err != nil {
		logrus.Errorf("Could not query database version :(")
		panic(err)
	}

	var version string
	response.Next()
	err = response.Scan(&version)
	if err != nil {
		logrus.Errorf("Could not scan version :(")
		panic(err)
	}
	defer response.Close()

	fmt.Printf("Yeey, database is reachable! Version is %s\n", version)
}

func healthyRobot() {

	http.HandleFunc("/_ready", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "I am ready :)\n")
	})
	http.HandleFunc("/_health", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "I am healthy.. have been drinking enough oil :)\n")
	})
	fmt.Println("Listening to peeky pokers")
	http.ListenAndServe(":3000", nil)
}

func main() {
	fmt.Println("Hello world! :)")

	pingDatabase()

	healthyRobot()
	fmt.Println("I am done, but me cogs still ruen!")
}
