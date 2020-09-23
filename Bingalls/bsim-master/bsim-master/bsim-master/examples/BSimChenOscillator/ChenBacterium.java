package BSimChenOscillator;

import bsim.BSim;
import bsim.BSimChemicalField;
import bsim.capsule.BSimCapsuleBacterium;
import javax.vecmath.Vector3d;
import java.awt.*;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.*;
import java.util.List;
import java.lang.Math;
import java.util.Random;
/**
 */
public class ChenBacterium extends BSimCapsuleBacterium {

    // TODO: parameters
    private double D_I = 2.1;
    private double phi_I = 2.0;

    //public ChenBacterium(BSim _sim, Vector3d _x1, Vector3d _x2) {
        //super(_sim, _x1, _x2);
    //}


    protected BSimChemicalField I_e_field;
    protected Boolean infected;

    public ChenBacterium(BSim sim, Vector3d px1, Vector3d px2, BSimChemicalField _I_e,Boolean infected){
        super(sim, px1, px2);

        D_I = ChenParameters.p.get("D_I");
        phi_I = ChenParameters.p.get("phi_I");


        this.I_e_field = _I_e;
        this.infected = infected;
    }



    @Override
    public void action() {
        super.action();

        double i_e;	// External Q2
        double i_Delta;		// Change in Q2

        // external chemical level at position of the bacterium:
        i_e = I_e_field.getConc(position);
        double i_ecrit=0.5;
        // Get the external chemical field level for the GRN dde system later on:
        //grn.setExternalFieldLevel(h_e, i_e);

        // Adjust the external chemical field
        //i_Delta = i_e -phi_I/60.0;

        i_Delta = 0.0;

        Random checkInfected = new Random();
        double cI = checkInfected.nextDouble();

//        if(infected) {
//            i_Delta = i_e - phi_I;
//        }
//        else{
//            i_Delta = i_e;
//            if(i_e>=i_ecrit && cI>=0.8){
//                infected=true;
//            }
//        }
        // TODO: re-scale time units.
        I_e_field.addQuantity(position, D_I*(-i_Delta)/60.0);

    }

    @Override
    public void setK_growth(double k_growth) {
        super.setK_growth(k_growth);
    }




    public ChenBacterium divide(Boolean infected) {

        System.out.println("Bacterium " + this.id + " is dividing...");

        Vector3d u = new Vector3d(); u.sub(this.x2, this.x1);

        // Uniform Distn; Change to Normal?
        double divPert = 0.1*L_max*(rng.nextDouble() - 0.5);

        double L_actual = u.length();

        double L1 = L_actual*0.5*(1 + divPert) - radius;
        double L2 = L_actual*0.5*(1 - divPert) - radius;

        // Use for dividing the cell contents according to the length fraction of the mother and child.
//        double childProportion = L2/L_actual;
//        double thisProportion = 1 - childProportion;

        ///
        Vector3d x2_new = new Vector3d();
        x2_new.scaleAdd(L1/L_actual, u, this.x1);
        x2_new.add(new Vector3d(0.05*L_initial*(rng.nextDouble() - 0.5),
                0.05*L_initial*(rng.nextDouble() - 0.5), //what do these two blocks of code do?? -catie
                0.05*L_initial*(rng.nextDouble() - 0.5)));

        Vector3d x1_child = new Vector3d();
        x1_child.scaleAdd(-(L2/L_actual), u, this.x2);
        x1_child.add(new Vector3d(0.05*L_initial*(rng.nextDouble() - 0.5),
                0.05*L_initial*(rng.nextDouble() - 0.5),
                0.05*L_initial*(rng.nextDouble() - 0.5)));



        // Set the child cell.
        ////
        // TODO? Ideally initialise all four co-ordinates, otherwise this operation is order-dependent
        // (this.xi could be overwritten before being passed to child for ex.)
        ChenBacterium child;
        if(infected){
            child = new ChenBacterium(sim, x1_child, new Vector3d(this.x2), I_e_field, Boolean.TRUE);


        }
        else{
            child = new ChenBacterium(sim, x1_child, new Vector3d(this.x2), I_e_field, Boolean.FALSE);

        }
        this.initialise(L1, this.x1, x2_new); //what does initialize do ?? -catie
        child.L = L2;
        System.out.println("Child ID id " + child.id);
        return child;
    }
    int count=0;

    public void set_count(int n){
        this.count = n;
    }

    public int get_count(){
        return count;
    }

}
